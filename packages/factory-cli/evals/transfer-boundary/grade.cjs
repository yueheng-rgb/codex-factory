const {test}=require('node:test');
const a=require('node:assert/strict');
const path=require('node:path');
const root=process.env.FACTORY_TRIAL_ROOT;
const id=process.env.FACTORY_CASE_ID;
if (!root || !['t3','t4'].includes(id)) throw Error('Controller must supply root and case');
const f=require(path.join(root,'src',id==='t3'?'tickets.cjs':'messages.cjs'))[id==='t3'?'ingestTickets':'ingestMessages'];
const row=(ticket,cents=1,direction='credit')=>({ticket,cents,direction});
test('exact boundary, prefix, zeroes and Unicode',()=>{
  const inputs=[' ORD:0007 ','ord:007','ORD:ORD:0007','ORD: 07','0','__proto__','constructor','e\u0301','\u00e9'];
  const keys=id==='t3'?['0007','ord:007','ORD:0007',' 07','0','__proto__','constructor','e\u0301','\u00e9']:inputs;
  a.deepEqual(f(inputs.map(x=>row(x))),{entries:keys.map(key=>({key,deltaCents:1})),netCents:inputs.length});
});
test('blank remainder belongs only to import boundary',()=>{
  for(const ticket of ['ORD:',' ORD:   ']) {
    if(id==='t3') a.throws(()=>f([row(ticket)]),TypeError);
    else a.deepEqual(f([row(ticket)]),{entries:[{key:ticket,deltaCents:1}],netCents:1});
  }
});
test('stable duplicates, fresh objects, positive zero and no extra fields',()=>{
  const rows=[row('X',0,'debit'),row('X',7,'debit'),{...row('Y',9),ignored:'drop'}];
  const copy=structuredClone(rows); rows.forEach(Object.freeze);Object.freeze(rows);
  const out=f(rows);
  a.deepEqual(out,{entries:[{key:'X',deltaCents:0},{key:'X',deltaCents:-7},{key:'Y',deltaCents:9}],netCents:2});
  a.deepEqual(rows,copy);out.entries.forEach((entry,i)=>a.notEqual(entry,rows[i]));
});
test('validate shapes and every field, including discarded-looking duplicates',()=>{
  for(const value of [null,{},'x',1]) a.throws(()=>f(value),TypeError);
  for(const bad of [null,[],1,{},row(0),row(null),row(' '),row('X',-1),row('X',Infinity),row('X',1.2),row('X',1,'refund')]) {
    a.throws(()=>f([row('X'),bad]),TypeError);
  }
});
test('safe integer running totals and empty input',()=>{
  a.deepEqual(f([]),{entries:[],netCents:0});
  a.throws(()=>f([row('A',Number.MAX_SAFE_INTEGER),row('B',1)]),RangeError);
  a.throws(()=>f([row('A',Number.MAX_SAFE_INTEGER,'debit'),row('B',1,'debit')]),RangeError);
  a.throws(()=>f([row('A',Number.MAX_SAFE_INTEGER),row('B',1),row('C',1,'debit')]),RangeError);
});
test('existing accepted legacy conversion and unrelated behavior remain',()=>{
  a.equal(require(path.join(root,'src/legacy.cjs')).reference(' ORD:0004 '),'0004');
  a.deepEqual(require(path.join(root,'src/health.cjs')).health(),{status:'ok'});
  a.deepEqual(require(path.join(root,'src/lookup.cjs')).lookup([{key:'A'},{key:'B'}],'B'),[{key:'B'}]);
});
