import type { FactoryTask } from "../../src/types.js";

export type CaseId = "t5" | "t6";
export const caseIds = ["t5", "t6"] as const;
export const diagnosticGuidance = "Controller guidance (not probe-module integration): form competing hypotheses and inspect the shared diagnostic before editing. Limit this to one brief hypothesis comparison; use the same visible diagnostic available to every arm.";

const correctMapping = `exports.mapRows = rows => rows.map(row => ({id:row.id,kind:row.kind,deltaCents:row.cents===0?0:row.kind==='return'?-row.cents:row.cents}));\n`;
const baseSummary = `const {sum}=require('./money.cjs');
exports.summarize = entries => ({orderCount:entries.length,netCents:sum(entries.map(entry=>entry.deltaCents))});
`;

export const common: Record<string, string> = {
  "src/reader.cjs": "const fs=require('node:fs');exports.readRows=path=>JSON.parse(fs.readFileSync(path,'utf8'));\n",
  "src/validate.cjs": `exports.validate=rows=>{
  if(!Array.isArray(rows)||rows.length>1000)throw TypeError('Expected at most 1000 rows');
  for(const row of rows)if(!row||typeof row!=='object'||Array.isArray(row)||typeof row.id!=='string'||!row.id.trim()||!['sale','return'].includes(row.kind)||!Number.isInteger(row.cents)||row.cents<0||row.cents>1000000)throw TypeError('Invalid row');
};
`,
  "src/mapping.cjs": correctMapping,
  "src/money.cjs": "exports.sum=values=>values.reduce((total,value)=>total+value,0);\n",
  "src/summary.cjs": baseSummary,
  "src/reconcile.cjs": `const {validate}=require('./validate.cjs');const {mapRows}=require('./mapping.cjs');const {summarize}=require('./summary.cjs');
exports.reconcile=rows=>{validate(rows);const entries=mapRows(rows);return {entries,summary:summarize(entries)};};
`,
  "src/diagnostics.cjs": `const {validate}=require('./validate.cjs');const {mapRows}=require('./mapping.cjs');const {summarize}=require('./summary.cjs');
exports.inspect=rows=>{validate(rows);const entries=mapRows(rows);return {readCount:rows.length,rawKinds:rows.map(row=>row.kind),rawCents:rows.map(row=>row.cents),mappedDeltaCents:entries.map(entry=>entry.deltaCents),summary:summarize(entries)};};
`,
  "cli.cjs": `const {readRows}=require('./src/reader.cjs');
try{const [mode,path,...extra]=process.argv.slice(2);if(!path||extra.length||!['report','diagnose'].includes(mode))throw Error('Usage: node cli.cjs report|diagnose input.json');
const rows=readRows(path);const result=mode==='diagnose'?require('./src/diagnostics.cjs').inspect(rows):require('./src/reconcile.cjs').reconcile(rows);console.log(JSON.stringify(result));
}catch(error){console.error(error.message);process.exitCode=1;}
`,
  "data/repro.json": JSON.stringify([{ id: "007", kind: "sale", cents: 125 }, { id: "007", kind: "return", cents: 40 }, { id: "Z", kind: "return", cents: 0 }], null, 2) + "\n",
  "README.md": "# Offline reconciliation development fixture\nRead TASK.md and docs/contract.md. Run node --test public.test.cjs; node cli.cjs report data/repro.json; node cli.cjs diagnose data/repro.json. No dependencies are needed.\n",
};

export function taskFor(id: CaseId): FactoryTask {
  return {
    task_id: "worker", title: id === "t5" ? "Locate incorrect reconciliation total" : "Add returnCount to summaries",
    description: (id === "t5"
      ? "The reproduction report has an incorrect total. Locate and fix the injected defect using the existing reader, conversion and summary code."
      : "Add summary.returnCount, counting return rows including zero amounts and duplicate IDs.") +
      " Read docs/contract.md for the complete frozen behavior. Run node --test public.test.cjs. The shared diagnostic is node cli.cjs diagnose data/repro.json; its readable mappedDeltaCents field is available to every arm. Use Node builtins only. Preserve frozen files. Optional self.test.cjs is allowed. No child agents.",
    role: "implementation", status: "pending", dependencies: [],
    write_scope: id === "t5"
      ? ["src/reader.cjs", "src/validate.cjs", "src/mapping.cjs", "src/money.cjs", "src/summary.cjs", "src/reconcile.cjs", "self.test.cjs"]
      : ["src/summary.cjs", "self.test.cjs"],
    required_artifacts: [id === "t5" ? "src/reconcile.cjs" : "src/summary.cjs"],
    acceptance_methods: ["command:node --test public.test.cjs"],
  };
}

export function inputs(id: CaseId): Record<string, string> {
  return {
    ...common,
    "src/mapping.cjs": id === "t5" ? correctMapping.replace("row.kind==='return'", "row.kind==='refund'") : correctMapping,
    "TASK.md": taskFor(id).description + "\n",
    "docs/contract.md": `# Frozen synthetic development contract: ${id.toUpperCase()}
No UI, network, authentication or database. This is authored evaluation data.
reconcile(rows), exported from src/reconcile.cjs, accepts dense arrays of at most 1000 records.
Each row has a nonblank string id, kind exactly sale or return, and integer cents from 0 through 1000000 inclusive. Reject invalid inputs with TypeError. Extra row fields are ignored. Do not mutate inputs or reuse input objects in outputs.
Return exactly {entries,summary}. entries preserve row order and duplicate IDs, and contain exactly {id,kind,deltaCents}. Preserve id text exactly. Sale deltas are positive cents; return deltas are negative cents; every zero delta is positive zero.
summary contains exactly orderCount (number of rows), netCents (sum of deltas)${id === "t6" ? ", and returnCount (number of return rows, including zero cents and repeated IDs)" : ""}. Empty arrays yield empty entries and all summary fields zero.
The reproduction has deltas [125,-40,0], orderCount 3 and netCents 85${id === "t6" ? ", with returnCount 2" : ""}.
node cli.cjs report data/repro.json prints the reconciliation JSON. node cli.cjs diagnose data/repro.json prints {readCount,rawKinds,rawCents,mappedDeltaCents,summary}. Diagnostic raw fields reflect the validated input, mappedDeltaCents reflects conversion, and summary reflects the report summary. Invalid CLI input exits nonzero. Both commands and these diagnostic fields are shared by all arms.
Frozen public tests, CLI, diagnostics, data and documentation must not change. Implement the behavior in the declared scope; optional self.test.cjs is allowed. External checks only test this contract.
`,
    "public.test.cjs": publicTest(id),
  };
}

export function publicTest(id: CaseId) {
  const extra = id === "t6" ? ",returnCount:2" : "";
  return `const {test}=require('node:test');const a=require('node:assert/strict');const {reconcile}=require('./src/reconcile.cjs');
test('reproduction report',()=>a.deepEqual(reconcile(require('./data/repro.json')),{entries:[{id:'007',kind:'sale',deltaCents:125},{id:'007',kind:'return',deltaCents:-40},{id:'Z',kind:'return',deltaCents:0}],summary:{orderCount:3,netCents:85${extra}}}));
test('empty',()=>a.deepEqual(reconcile([]),{entries:[],summary:{orderCount:0,netCents:0${id === "t6" ? ",returnCount:0" : ""}}}));
test('invalid amount',()=>a.throws(()=>reconcile([{id:'x',kind:'sale',cents:-1}]),TypeError));
`;
}

// Controller-only material. Never copy these exports to a Worker project.
export function reference(id: CaseId): Record<string, string> {
  return id === "t5" ? { "src/mapping.cjs": correctMapping } : {
    "src/summary.cjs": baseSummary.replace("orderCount:entries.length,", "orderCount:entries.length,returnCount:entries.filter(entry=>entry.kind==='return').length,"),
  };
}

export function externalGrader(id: CaseId) {
  return `const {test}=require('node:test');const a=require('node:assert/strict');const {createRequire}=require('node:module');const {join}=require('node:path');const {spawnSync}=require('node:child_process');
const root=process.env.FACTORY_TRIAL_ROOT;const req=createRequire(join(root,'cli.cjs'));const {reconcile}=req('./src/reconcile.cjs');
const expected=rows=>({entries:rows.map(row=>({id:row.id,kind:row.kind,deltaCents:row.cents===0?0:row.kind==='sale'?row.cents:-row.cents})),summary:{orderCount:rows.length,netCents:rows.reduce((n,row)=>n+(row.kind==='sale'?row.cents:-row.cents),0)${id === "t6" ? ",returnCount:rows.filter(row=>row.kind==='return').length" : ""}}});
test('contract behavior, all-return, zero, duplicates, bounds and no mutation',()=>{
const groups=[[],[{id:'same',kind:'return',cents:0}],[{id:'same',kind:'return',cents:1000000},{id:'same',kind:'return',cents:0}],Array.from({length:1000},(_,i)=>({id:i%2?' 007 ':'ORD:007',kind:i%3?'return':'sale',cents:i%5?i*17:0,extra:'ignored'}))];
for(const rows of groups){const original=structuredClone(rows);const got=reconcile(rows);const want=expected(rows);a.deepEqual(got,want);a.deepEqual(rows,original);got.entries.forEach((entry,i)=>a.notEqual(entry,rows[i]));a.deepEqual(req('./src/diagnostics.cjs').inspect(rows),{readCount:rows.length,rawKinds:rows.map(row=>row.kind),rawCents:rows.map(row=>row.cents),mappedDeltaCents:want.entries.map(entry=>entry.deltaCents),summary:want.summary});}
});
test('reject every invalid row and input shape',()=>{
const valid={id:'ok',kind:'sale',cents:1};const bad=[null,[],{}, {...valid,id:' '},{...valid,id:4},{...valid,kind:'refund'},{...valid,cents:-1},{...valid,cents:0.5},{...valid,cents:1000001},{...valid,cents:NaN},{...valid,cents:Infinity}];
for(const row of bad)a.throws(()=>reconcile([valid,row]),TypeError);
for(const value of [null,{},'rows',Array.from({length:1001},()=>valid)])a.throws(()=>reconcile(value),TypeError);
});
test('shared reader, CLI, diagnostic and report agree',()=>{
const rows=req('./data/repro.json');const report=expected(rows);const env={...process.env};delete env.NODE_TEST_CONTEXT;
for(const mode of ['report','diagnose']){const r=spawnSync(process.execPath,['cli.cjs',mode,'data/repro.json'],{cwd:root,encoding:'utf8',timeout:5000,windowsHide:true,env});a.equal(r.status,0,r.stderr);a.deepEqual(JSON.parse(r.stdout),mode==='report'?report:{readCount:rows.length,rawKinds:rows.map(row=>row.kind),rawCents:rows.map(row=>row.cents),mappedDeltaCents:report.entries.map(entry=>entry.deltaCents),summary:report.summary});}
const invalid=spawnSync(process.execPath,['cli.cjs','report','missing.json'],{cwd:root,timeout:5000,windowsHide:true,env});a.notEqual(invalid.status,0);
});
`;
}
