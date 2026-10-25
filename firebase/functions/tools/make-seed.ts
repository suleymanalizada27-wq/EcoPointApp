import { writeFileSync } from 'node:fs';
import { BUILT_IN_CATALOG } from '../src/catalog';

const out: Record<string, unknown> = {};
for (const { id, ...rest } of BUILT_IN_CATALOG) out[id] = rest;
writeFileSync(new URL('../../seed/rewards.json', import.meta.url), JSON.stringify(out, null, 2) + '\n');
console.log(`wrote ${BUILT_IN_CATALOG.length} rewards`);
