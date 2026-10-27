import { describe, expect, it } from 'vitest';
import { MemoryStore } from '../src/store';
import { adminStats } from '../src/services/stats';
import { credit } from '../src/services/wallet';
import { ensureProfile } from '../src/services/profile';
import { ALICE, NOW, deps } from './helpers';

describe('admin stats', () => {
  it('counts signups and earned EP per day and ranks rewards', async () => {
    const s = new MemoryStore();
    await ensureProfile(deps(s), ALICE, { name: 'Alice', email: 'a@x.az' });
    await ensureProfile(deps(s), ALICE, { name: 'Alice', email: 'a@x.az' }); // idempotent
    await credit(s, ALICE, 50, { type: 'earn', desc: 'scan' }, NOW, { earned: true });
    await credit(s, ALICE, 50, { type: 'earn', desc: 'scan' }, NOW, { earned: true });
    await credit(s, ALICE, 20, { type: 'bonus', desc: 'gift' }, NOW);
    await s.set('statsRewards/a', { name: 'Kofe', count: 3 });
    await s.set('statsRewards/b', { name: 'Çay', count: 7 });
    const r = await adminStats(s, NOW, 14);
    expect(r.days).toHaveLength(14);
    const today = r.days[13];
    expect(today).toMatchObject({ signups: 1, earnedEp: 100, earns: 2 });
    expect(r.days[0].signups).toBe(0);
    expect(r.topRewards.map((x) => x.name)).toEqual(['Çay', 'Kofe']);
  });
});
