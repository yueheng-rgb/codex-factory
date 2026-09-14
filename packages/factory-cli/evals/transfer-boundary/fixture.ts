import type { FactoryTask } from "../../src/types.js";
import type { TeachingProposal } from "../../src/teaching.js";

export type CaseId = "t3" | "t4";
export const before = "exports.reference = raw => String(raw).trim().replace(/^ORD:/i, '').replace(/^0+/, '');\n";
export const after = `exports.reference = raw => {
  if (typeof raw !== 'string') throw new TypeError('Expected text');
  const text = raw.trim();
  const result = text.startsWith('ORD:') ? text.slice(4) : text;
  if (!result.trim()) throw new TypeError('Blank key');
  return result;
};
`;
export const lesson: TeachingProposal = {
  version: "1.0.0", name: "vendor-import-reference",
  description: "Preserve opaque order reference identifiers in vendor import adapters.",
  applies_when: ["Vendor import order references follow the accepted historical ORD: marker convention."],
  do_not_apply_when: ["Strict reference messages preserve exact raw input strings and do not use import normalization."],
  rules: [{ instruction: "Validate strings; trim outer whitespace; remove exactly one case-sensitive ORD: prefix; preserve leading zeros and remaining characters; reject blank identifiers.",
    before_excerpt: before.trim(), after_excerpt: after.trim(), rationale: "These are opaque business keys, not numbers or case-insensitive labels." }],
  example: { scenario: "A legacy vendor supplies ORD:00042", expected_behavior: "The imported identifier is 00042, not 42." },
  counterexample: { scenario: "A strict reference message supplies ORD:00042", expected_behavior: "Keep ORD:00042 unchanged; do not apply import rules." },
};

export const common: Record<string, string> = {
  "src/legacy.cjs": after,
  "src/money.cjs": "exports.sum = values => { let n=0; for(const v of values) { if(!Number.isSafeInteger(v)||!Number.isSafeInteger(n+v)) throw new RangeError('Unsafe cents'); n+=v; } return n; };\n",
  "src/snapshot.cjs": "exports.snapshot = rows => rows.map(row => ({...row}));\n",
  "src/lookup.cjs": "exports.lookup = (rows,key) => rows.filter(row => row.key === key);\n",
  "src/health.cjs": "exports.health = () => ({status:'ok'});\n",
  "src/tickets.cjs": "exports.ingestTickets = rows => { throw new Error('Not implemented'); };\n",
  "src/messages.cjs": "exports.ingestMessages = rows => { throw new Error('Not implemented'); };\n",
  "cli.cjs": "const fs=require('node:fs');try{const [mode,path,...extra]=process.argv.slice(2);if(!path||extra.length||!['tickets','messages'].includes(mode))throw Error('Usage: node cli.cjs tickets|messages input.json');const m=require('./src/'+mode+'.cjs');console.log(JSON.stringify(m[mode==='tickets'?'ingestTickets':'ingestMessages'](JSON.parse(fs.readFileSync(path,'utf8')))));}catch(e){console.error(e.message);process.exitCode=1;}\n",
  "docs/history.md": "# Synthetic history, available to every arm\nThe old vendor adapter damaged business keys through coercion and numeric normalization. The accepted fix is src/legacy.cjs; its previous version is docs/legacy-before.txt and local Git history.\nFor that import convention, require strings, trim outer whitespace, strip exactly one case-sensitive leading ORD:, reject blank remaining text, preserve every remaining code point and leading zero. Do not normalize Unicode, strip lowercase ord:, or remove a second prefix.\nStrict reference messages use a different boundary: exact original text is preserved, including surrounding whitespace and ORD:. Import compatibility must not cross this boundary.\nThese are authored evaluation facts, not a real customer incident.\n",
  "docs/legacy-before.txt": before,
  "docs/current.md": "# Current contracts\nT3: fulfilment tickets follow the same business-key convention as the corrected legacy feed.\nT4: strict reference messages reject non-string or all-whitespace keys, but preserve valid text exactly. No trimming, prefix removal, case folding, or Unicode normalization. The current boundary overrides historical import behavior.\nBoth: inputs are dense arrays of non-null, non-array records {ticket,cents,direction}. cents is a nonnegative safe integer, direction is credit or debit. Produce {entries:[{key,deltaCents}],netCents}. Preserve order and duplicate keys as separate entries. Drop additional fields. Debit negates positive cents, but zero must always be positive zero. Validate every row, including the last. netCents uses safe integer running sums; overflow at any step throws RangeError. Invalid shapes or fields throw TypeError. Do not mutate inputs or alias output objects to input records. Empty input is valid.\n",
  "README.md": "# Fulfilment reconciliation fixture\nNode builtins only. Run node --test public.test.cjs or node cli.cjs tickets|messages input.json. Read TASK.md, docs/current.md and docs/history.md.\n",
};

export const definitions: Record<CaseId, { module: string; entry: string; title: string; request: string }> = {
  t3: { module: "tickets", entry: "ingestTickets", title: "Reconcile fulfilment receipts",
    request: "The logistics feed now sends ticket text rather than the old field name. Carry the corrected legacy feed's business-key behavior into this new shape, using the available history. Implement src/tickets.cjs exporting ingestTickets(rows)." },
  t4: { module: "messages", entry: "ingestMessages", title: "Implement strict reference messages",
    request: "Implement src/messages.cjs exporting ingestMessages(rows). This is the strict reference message boundary, not vendor import normalization. Valid ticket text must be preserved exactly, including outer whitespace and ORD:. Reject non-string or all-whitespace ticket values. Current requirements take precedence over the historical import adapter." },
};
export function taskFor(id: CaseId): FactoryTask {
  const item = definitions[id];
  return { task_id: "worker", title: item.title,
    description: item.request + " Read TASK.md, docs/current.md and docs/history.md; all conversion, validation and total rules in docs/current.md are required. Use Node builtins only. Preserve unrelated modules, CLI and frozen inputs. You may add self.test.cjs. Run node --test public.test.cjs and any self-tests. No new dependencies or child agents.",
    role: "implementation", status: "pending", dependencies: [], write_scope: ["src/" + item.module + ".cjs", "self.test.cjs"],
    required_artifacts: ["src/" + item.module + ".cjs"], acceptance_methods: ["command:node --test public.test.cjs"] };
}
export function publicTest(id: CaseId) {
  const item = definitions[id];
  return `const {test}=require('node:test');const a=require('node:assert/strict');const f=require('./src/${item.module}.cjs').${item.entry};
test('empty',()=>a.deepEqual(f([]),{entries:[],netCents:0}));
test('conversion',()=>a.deepEqual(f([{ticket:'ORD:007',cents:25,direction:'credit'},{ticket:'Z',cents:10,direction:'debit'}]),{entries:[{key:'${id === "t3" ? "007" : "ORD:007"}',deltaCents:25},{key:'Z',deltaCents:-10}],netCents:15}));
test('validation',()=>a.throws(()=>f([{ticket:'A',cents:1.5,direction:'credit'}]),TypeError));
`;
}

// Controller-only calibration code; never copied into an evaluated root.
export function reference(id: CaseId, keyExpression = id === "t3" ? "reference(r.ticket)" : "r.ticket") {
  const item = definitions[id];
  return `const {reference}=require('./legacy.cjs');const {sum}=require('./money.cjs');
exports.${item.entry}=rows=>{if(!Array.isArray(rows))throw TypeError();const entries=rows.map(r=>{
if(!r||typeof r!=='object'||Array.isArray(r)||typeof r.ticket!=='string'||!r.ticket.trim()||!Number.isSafeInteger(r.cents)||r.cents<0||!['credit','debit'].includes(r.direction))throw TypeError();
return {key:${keyExpression},deltaCents:r.cents===0?0:r.direction==='debit'?-r.cents:r.cents};});return {entries,netCents:sum(entries.map(r=>r.deltaCents))};};\n`;
}
