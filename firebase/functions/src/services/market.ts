import { BUILT_IN_CATALOG, type CatalogItem } from '../catalog';
import { COUPON_PARTNERS, CONFIG, type PartnerId } from '../lib/config';
import { isPositiveInt, percentFee, randomCode } from '../lib/rules';
import { Errors } from '../errors';
import type { Deps } from './context';
import { secureRng } from './context';
import type { Store } from '../store';
import { assertNotBanned, debit, increment, once } from './wallet';
import { bumpReward, bumpStat } from './stats';

/** `rewards/` is authoritative when it has content; else the built-in list. */
export async function getReward(store: Store, id: string): Promise<CatalogItem | null> {
  const all = await store.get<Record<string, any>>('rewards');
  if (all && Object.keys(all).length > 0) {
    const r = all[id];
    if (!r || typeof r.ep !== 'number') return null;
    return {
      id,
      name: r.name ?? { az: id, en: id, ru: id, tr: id },
      brand: String(r.brand ?? ''),
      ep: r.ep,
      cat: r.cat ?? 'service',
      icon: String(r.icon ?? ''),
      kind: r.kind ?? 'item',
      partnerId: r.partnerId,
      stock: typeof r.stock === 'number' ? r.stock : undefined,
      active: r.active !== false,
    };
  }
  return BUILT_IN_CATALOG.find((i) => i.id === id) ?? null;
}

export interface PurchaseResult {
  balance: number;
}

export async function purchaseReward(
  { store, now }: Deps,
  uid: string,
  input: { rewardId: unknown; requestId: unknown },
): Promise<PurchaseResult> {
  if (typeof input.rewardId !== 'string' || input.rewardId.length > 64) {
    throw Errors.invalid('Invalid reward');
  }
  const rewardId = input.rewardId;

  return once(store, uid, input.requestId, now, async () => {
    await assertNotBanned(store, uid);
    const item = await getReward(store, rewardId);
    if (!item || !item.active) throw Errors.notFound('Reward');
    if (item.kind !== 'item') throw Errors.invalid('Use the dedicated flow');

    // Reserve stock first (only for catalogs that track it).
    const tracksStock = item.stock !== undefined;
    if (tracksStock) {
      let ok = false;
      await store.transaction(`rewards/${rewardId}/stock`, (cur) => {
        if (cur === null || cur === undefined) {
          ok = false;
          return 0;
        }
        if (typeof cur !== 'number' || cur <= 0) {
          ok = false;
          return undefined;
        }
        ok = true;
        return cur - 1;
      });
      if (!ok) throw Errors.outOfStock();
    }

    try {
      const name = item.name.az;
      const balance = await debit(
        store,
        uid,
        item.ep,
        { type: 'purchase', desc: `🛍 ${name}` },
        now,
      );
      await increment(store, `users/${uid}/stats/spent`, item.ep);
      await bumpStat(store, now, 'spentEp', item.ep);
      await bumpStat(store, now, 'purchases', 1);
      await bumpReward(store, rewardId, name, now);
      await store.push(`users/${uid}/purchases`, {
        name,
        price: item.ep,
        rewardId,
        ts: now,
        status: 'completed',
      });
      return { balance };
    } catch (e) {
      if (tracksStock) await increment(store, `rewards/${rewardId}/stock`, 1);
      throw e;
    }
  });
}

export interface CouponResult {
  balance: number;
  code: string;
  azn: number;
}

export async function createCoupon(
  { store, now }: Deps,
  uid: string,
  input: { partnerId: unknown; ep: unknown; requestId: unknown },
): Promise<CouponResult> {
  const partner = COUPON_PARTNERS[input.partnerId as PartnerId];
  if (!partner || typeof input.partnerId !== 'string') throw Errors.invalid('Unknown partner');
  if (!isPositiveInt(input.ep, partner.minEp, CONFIG.couponMaxEp)) {
    throw Errors.invalid(`Minimum ${partner.minEp} EP`);
  }
  const ep = input.ep;

  return once(store, uid, input.requestId, now, async () => {
    await assertNotBanned(store, uid);
    const fee = percentFee(ep, CONFIG.couponCommissionPercent);
    const azn = Math.round(((ep - fee) / partner.epPerAzn) * 100) / 100;
    const code = `${partner.id.slice(0, 3).toUpperCase()}-${randomCode(8, secureRng)}`;

    const balance = await debit(
      store,
      uid,
      ep,
      { type: 'purchase', desc: `🎟 ${partner.name} coupon` },
      now,
    );
    await increment(store, `users/${uid}/stats/spent`, ep);
    await bumpStat(store, now, 'spentEp', ep);
    await bumpStat(store, now, 'purchases', 1);
    await bumpReward(store, `coupon_${partner.id}`, `${partner.name} kupon`, now);

    const record = { partnerId: partner.id, ep, fee, azn, code, ts: now, status: 'issued' };
    await store.push(`users/${uid}/coupons`, record);
    await store.set(`coupons/${code}`, { uid, ...record });
    await store.push(`users/${uid}/purchases`, {
      name: `${partner.name} coupon`,
      price: ep,
      code,
      ts: now,
      status: 'completed',
    });
    return { balance, code, azn };
  });
}

export async function requestTransportTopUp(
  { store, now }: Deps,
  uid: string,
  input: { cardNumber: unknown; ep: unknown; requestId: unknown },
): Promise<PurchaseResult> {
  const card = typeof input.cardNumber === 'string' ? input.cardNumber.replace(/\s/g, '') : '';
  if (!/^\d{16}$/.test(card)) throw Errors.invalid('Invalid card number');
  if (!isPositiveInt(input.ep, CONFIG.transportMinEp, CONFIG.transportMaxEp)) {
    throw Errors.invalid(`Minimum ${CONFIG.transportMinEp} EP`);
  }
  const ep = input.ep;

  return once(store, uid, input.requestId, now, async () => {
    await assertNotBanned(store, uid);
    const fee = percentFee(ep, CONFIG.transportFeePercent);
    const balance = await debit(
      store,
      uid,
      ep,
      { type: 'purchase', desc: `🚌 BakıKart •••• ${card.slice(-4)}`, status: 'pending' },
      now,
    );
    await increment(store, `users/${uid}/stats/spent`, ep);
    const purchaseId = await store.push(`users/${uid}/purchases`, {
      name: `BakıKart •••• ${card.slice(-4)}`,
      price: ep,
      ts: now,
      status: 'pending',
    });
    // Full card number only in the server-side queue.
    await store.push('transportRequests', {
      uid,
      card,
      ep,
      fee,
      netEp: ep - fee,
      purchaseId,
      status: 'pending',
      ts: now,
    });
    return { balance };
  });
}
