import { CONFIG } from '../lib/config';
import { cleanText, isPositiveInt, isUid, validName } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import {
  assertNotBanned,
  credit,
  debit,
  increment,
  notify,
  once,
  rateLimit,
} from './wallet';

export interface TransferResult {
  transferId: string;
  balance: number;
  recipientName: string;
}

export async function transferEp(
  { store, now, push }: Deps,
  uid: string,
  input: { recipientUid: unknown; amount: unknown; requestId: unknown },
): Promise<TransferResult> {
  const { recipientUid, amount } = input;
  if (typeof recipientUid !== 'string' || !isUid(recipientUid)) {
    throw Errors.invalid('Invalid recipient');
  }
  if (recipientUid === uid) throw Errors.selfTransfer();
  if (!isPositiveInt(amount, CONFIG.minTransferEp, CONFIG.maxTransferEp)) {
    throw Errors.invalid('Invalid amount');
  }

  return once(store, uid, input.requestId, now, async () => {
    await assertNotBanned(store, uid);
    await rateLimit(store, `transfer/${uid}`, now, {
      windowMs: 3_600_000,
      max: CONFIG.maxTransfersPerHour,
    });

    const recipient = await store.get<any>(`users/${recipientUid}`);
    if (!recipient) throw Errors.notFound('Recipient');
    const sender = await store.get<any>(`users/${uid}`);
    const senderName = cleanText(sender?.name, CONFIG.nameMax) || 'EcoPoint';
    const recipientName = cleanText(recipient.name, CONFIG.nameMax) || '—';

    // 1) debit sender (atomic, refuses to go negative)
    const balance = await debit(
      store,
      uid,
      amount,
      { type: 'sent', desc: `⬆ ${recipientName}` },
      now,
    );
    await increment(store, `users/${uid}/stats/sent`, amount);

    // 2) credit recipient; on any failure give the sender their EP back
    try {
      await credit(
        store,
        recipientUid,
        amount,
        { type: 'received', desc: `⬇ ${senderName}` },
        now,
      );
    } catch (e) {
      await credit(
        store,
        uid,
        amount,
        { type: 'other', desc: '↩ Transfer refunded' },
        now,
      );
      await increment(store, `users/${uid}/stats/sent`, -amount);
      throw e;
    }

    const transferId = await store.push('transfers', {
      from: uid,
      to: recipientUid,
      amount,
      ts: now,
    });
    await notify(store, recipientUid, `+${amount} EP`, `${senderName}`, now, push);
    return { transferId, balance, recipientName };
  });
}

export interface UserSummary {
  uid: string;
  name: string;
  photoURL: string;
  avatar: string;
}

export async function lookupUsers(
  { store, now }: Deps,
  uid: string,
  queryRaw: unknown,
): Promise<{ users: UserSummary[] }> {
  const query = cleanText(queryRaw, CONFIG.nameMax);
  if (query.length < 2) return { users: [] };
  await rateLimit(store, `lookup/${uid}`, now, { windowMs: 60_000, max: 30 });

  const toSummary = (id: string, v: any): UserSummary => ({
    uid: id,
    name: cleanText(v?.name, CONFIG.nameMax) || '—',
    photoURL: typeof v?.photoURL === 'string' ? v.photoURL : '',
    avatar: typeof v?.avatar === 'string' ? v.avatar : '',
  });

  if (isUid(query)) {
    const hit = await store.get<any>(`leaderboard/${query}`);
    return { users: hit && query !== uid ? [toSummary(query, hit)] : [] };
  }

  const rows = await store.queryByChildPrefix(
    'leaderboard',
    'nameLower',
    query.toLowerCase(),
    9,
  );
  return {
    users: rows
      .filter((r) => r.key !== uid && validName(cleanText(r.value?.name, CONFIG.nameMax)))
      .slice(0, 8)
      .map((r) => toSummary(r.key, r.value)),
  };
}
