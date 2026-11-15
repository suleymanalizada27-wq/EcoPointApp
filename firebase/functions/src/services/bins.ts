import { binFullText } from '../lib/notify-text';
import { cleanText, dayKey } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { countPush, pushIsDisabled } from './smart-push';
import { userLang, type ReminderEnv, type RunResult } from './reminders';
import { rateLimit } from './wallet';

const BIN_ID = /^[A-Za-z0-9_-]{1,64}$/;
const KINDS = new Set(['broken', 'full', 'dirty', 'other']);
/** Base64 JPEG, already shrunk by the app (≈ 100 KB). Hard cap. */
const MAX_PHOTO_CHARS = 350_000;
const MAX_FAVS = 10;
/** Distinct people who must report "broken" before the map shows "not working". */
const BROKEN_THRESHOLD = 2;
export const FULL_AT = 85;
export const FULL_RESET = 60;

async function binOrThrow(store: Deps['store'], id: unknown): Promise<string> {
  if (typeof id !== 'string' || !BIN_ID.test(id)) throw Errors.invalid('Invalid bin id');
  if ((await store.get(`devices/${id}`)) === null) throw Errors.notFound('Bin');
  return id;
}

// ───────────────────────── problem reports ─────────────────────────

export async function reportBin(
  { store, now }: Deps,
  uid: string,
  input: Record<string, unknown>,
): Promise<{ id: string }> {
  const binId = await binOrThrow(store, input.binId);
  const kind = typeof input.kind === 'string' && KINDS.has(input.kind) ? input.kind : null;
  if (!kind) throw Errors.invalid('Invalid kind');
  const note = cleanText(input.note, 200);
  let photo: string | null = null;
  if (input.photo !== undefined && input.photo !== null && input.photo !== '') {
    if (typeof input.photo !== 'string' || input.photo.length > MAX_PHOTO_CHARS || !/^[A-Za-z0-9+/=]+$/.test(input.photo)) {
      throw Errors.invalid('Invalid photo');
    }
    // JPEG ("/9j/") or PNG ("iVBOR") only.
    if (!input.photo.startsWith('/9j/') && !input.photo.startsWith('iVBOR')) throw Errors.invalid('Invalid photo');
    photo = input.photo;
  }
  await rateLimit(store, `binreport/${uid}`, now, { windowMs: 3_600_000, max: 6, minIntervalMs: 5_000 });
  // One open report per person per bin.
  const mine = await store.get(`binReportIndex/${binId}/${uid}`);
  if (mine) throw Errors.duplicate('Already reported');

  const ref = await store.push('binReports', {
    uid,
    binId,
    kind,
    note,
    ts: now,
    status: 'open',
    hasPhoto: photo !== null,
  });
  if (photo) await store.set(`binReportPhotos/${ref}`, photo);
  await store.set(`binReportIndex/${binId}/${uid}`, ref);

  if (kind === 'broken') {
    const idx = (await store.get<Record<string, string>>(`binReportIndex/${binId}`)) ?? {};
    const rows = await Promise.all(Object.values(idx).map((id) => store.get<any>(`binReports/${id}`)));
    const people = new Set(rows.filter((r) => r?.kind === 'broken' && r?.status === 'open').map((r) => r.uid));
    if (people.size >= BROKEN_THRESHOLD) await store.update(`devices/${binId}`, { problem: true });
  }
  return { id: ref };
}

export async function adminListReports({ store }: Deps): Promise<{ reports: unknown[] }> {
  const all = (await store.get<Record<string, any>>('binReports')) ?? {};
  const reports = Object.entries(all)
    .filter(([, r]) => r?.status === 'open')
    .map(([id, r]) => ({ id, binId: r.binId, kind: r.kind, note: r.note, uid: r.uid, ts: r.ts, hasPhoto: r.hasPhoto === true }))
    .sort((a, b) => Number(b.ts) - Number(a.ts))
    .slice(0, 200);
  return { reports };
}

export async function adminReportPhoto({ store }: Deps, id: unknown): Promise<{ photo: string | null }> {
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,40}$/.test(id)) throw Errors.invalid('Invalid id');
  return { photo: (await store.get<string>(`binReportPhotos/${id}`)) ?? null };
}

/** Marks a report resolved; with `clearProblem` the bin's "not working" flag is removed too. */
export async function adminResolveReport(
  { store, now }: Deps,
  adminUid: string,
  input: { id: unknown; clearProblem?: unknown },
): Promise<{ ok: true }> {
  if (typeof input.id !== 'string' || !/^[A-Za-z0-9_-]{1,40}$/.test(input.id)) throw Errors.invalid('Invalid id');
  const r = await store.get<any>(`binReports/${input.id}`);
  if (!r) throw Errors.notFound('Report');
  await store.update(`binReports/${input.id}`, { status: 'resolved', by: adminUid, resolvedAt: now });
  await store.remove(`binReportPhotos/${input.id}`);
  await store.remove(`binReportIndex/${r.binId}/${r.uid}`);
  if (input.clearProblem === true) await store.update(`devices/${r.binId}`, { problem: false });
  return { ok: true };
}

// ───────────────────────── favourite bins ─────────────────────────

export async function toggleFavBin(
  { store, now }: Deps,
  uid: string,
  input: { binId: unknown; on: unknown },
): Promise<{ favs: string[] }> {
  await rateLimit(store, `fav/${uid}`, now, { windowMs: 60_000, max: 30 });
  if (typeof input.binId !== 'string' || !BIN_ID.test(input.binId)) throw Errors.invalid('Invalid bin id');
  const binId = input.binId;
  const on = input.on === true;
  const cur = (await store.get<Record<string, unknown>>(`users/${uid}/favBins`)) ?? {};
  if (on) {
    await binOrThrow(store, binId);
    if (!cur[binId] && Object.keys(cur).length >= MAX_FAVS) throw Errors.invalid('Too many favourites');
    await store.set(`users/${uid}/favBins/${binId}`, true);
    await store.set(`favIndex/${binId}/${uid}`, true);
  } else {
    await store.remove(`users/${uid}/favBins/${binId}`);
    await store.remove(`favIndex/${binId}/${uid}`);
  }
  const next = (await store.get<Record<string, unknown>>(`users/${uid}/favBins`)) ?? {};
  return { favs: Object.keys(next) };
}

/**
 * Hourly: when a bin crosses FULL_AT %, tell the people who starred it
 * (once; re-armed after it drops below FULL_RESET %). Bins flagged as not
 * working are skipped, and people who switched activity notifications off.
 */
export async function runBinFullAlerts(env: ReminderEnv): Promise<RunResult> {
  const { store, now } = env;
  if (await pushIsDisabled(store)) return { considered: 0, sent: 0 };
  const devices = (await store.get<Record<string, any>>('devices')) ?? {};
  let considered = 0;
  let sent = 0;
  for (const [id, d] of Object.entries(devices)) {
    const pct = Number(d?.fillPercent);
    if (!Number.isFinite(pct)) continue;
    if (pct < FULL_RESET && d.alerted) {
      await store.update(`devices/${id}`, { alerted: false });
      continue;
    }
    if (pct < FULL_AT || d.alerted || d.problem === true || d.disabled === true) continue;
    // Stale readings are not alerts.
    if (!(Number(d.lastSeen) > 0) || now - Number(d.lastSeen) > 6 * 3_600_000) continue;
    const claim = await store.transaction(`devices/${id}/alerted`, (cur) => (cur ? undefined : true));
    if (!claim.committed) continue;
    const subs = (await store.get<Record<string, unknown>>(`favIndex/${id}`)) ?? {};
    const name = String(d.name ?? id);
    for (const uid of Object.keys(subs)) {
      considered++;
      try {
        if ((await store.get<boolean>(`users/${uid}/prefs/notifyBins`)) === false) continue;
        const lang = await userLang(store, uid);
        const text = binFullText(lang, name, Math.round(pct));
        await env.push.toUser(uid, { ...text, route: '/bins', kind: 'binFull', id: `${dayKey(now)}_${id}`.slice(0, 40) });
        await store.push(`users/${uid}/notifications`, { title: text.title, body: text.body, ts: now, kind: 'binFull' });
        await countPush(store, now, 'sent', 'binFull');
        sent++;
      } catch {
        /* best effort */
      }
    }
  }
  return { considered, sent };
}

