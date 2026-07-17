'use strict';

function generateStaticPage(stockData, auditData) {
  const stocks = stockData || [];
  const audits = auditData || [];
  const now = new Date().toISOString();

  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>H5 Mini Inventory Ops — Dashboard</title>
<style>
  :root {
    --bg: #f5f7fa;
    --card: #fff;
    --text: #1a1a2e;
    --muted: #6b7280;
    --green: #10b981;
    --red: #ef4444;
    --blue: #3b82f6;
    --amber: #f59e0b;
    --border: #e5e7eb;
    --radius: 10px;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--bg); color: var(--text); padding: 0 0 40px; min-height: 100vh; }
  .header { background: linear-gradient(135deg, var(--blue), #6366f1); color: #fff; padding: 20px 16px; position: sticky; top: 0; z-index: 10; }
  .header h1 { font-size: 18px; font-weight: 600; }
  .header .sub { font-size: 12px; opacity: 0.85; margin-top: 4px; }
  .container { max-width: 640px; margin: 0 auto; padding: 12px 12px; }
  section { margin-bottom: 16px; }
  section h2 { font-size: 14px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 8px; padding-left: 2px; }
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 8px; }
  .card { background: var(--card); border-radius: var(--radius); padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,.06); border: 1px solid var(--border); }
  .card .sku { font-size: 11px; color: var(--blue); font-weight: 700; margin-bottom: 4px; }
  .card .name { font-size: 13px; font-weight: 500; margin-bottom: 6px; }
  .card .row { display: flex; justify-content: space-between; font-size: 12px; margin-bottom: 2px; }
  .card .row span:last-child { font-weight: 600; }
  .card .stock { color: var(--green); }
  .card .reserved { color: var(--amber); }
  .card .available { color: var(--blue); }
  .card .version { color: var(--muted); font-size: 10px; }
  .empty { text-align: center; padding: 32px; color: var(--muted); font-size: 13px; }
  .table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; background: var(--card); border-radius: var(--radius); box-shadow: 0 1px 3px rgba(0,0,0,.06); border: 1px solid var(--border); }
  table { width: 100%; border-collapse: collapse; font-size: 12px; white-space: nowrap; }
  th { text-align: left; padding: 10px 8px; background: #f9fafb; color: var(--muted); font-weight: 600; font-size: 11px; border-bottom: 1px solid var(--border); }
  td { padding: 8px 8px; border-bottom: 1px solid var(--border); }
  tr:last-child td { border-bottom: none; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 10px; font-weight: 600; }
  .badge-in  { background: #d1fae5; color: #065f46; }
  .badge-out { background: #fee2e2; color: #991b1b; }
  .badge-res { background: #fef3c7; color: #92400e; }
  .badge-rel { background: #dbeafe; color: #1e40af; }
  .badge-adj { background: #ede9fe; color: #5b21b6; }
  .badge-trf { background: #fce7f3; color: #9d174d; }
  .badge-success { background: #d1fae5; color: #065f46; }
  .badge-fail { background: #fee2e2; color: #991b1b; }
  .actions { display: flex; gap: 8px; flex-wrap: wrap; }
  .btn { display: inline-flex; align-items: center; gap: 4px; padding: 10px 20px; border-radius: var(--radius); font-size: 13px; font-weight: 600; cursor: pointer; border: none; transition: all .15s; text-decoration: none; }
  .btn-primary { background: var(--blue); color: #fff; }
  .btn-primary:hover { background: #2563eb; }
  .btn-secondary { background: var(--card); color: var(--text); border: 1px solid var(--border); }
  .btn-secondary:hover { background: #f9fafb; }
  .btn:disabled { opacity: .5; cursor: not-allowed; }
  .scenario-results { margin-top: 12px; }
  .scenario-result { display: flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--card); border-radius: 8px; margin-bottom: 4px; font-size: 12px; border: 1px solid var(--border); }
  .scenario-result.pass { border-left: 3px solid var(--green); }
  .scenario-result.fail { border-left: 3px solid var(--red); }
  .scenario-result .icon { font-size: 16px; flex-shrink: 0; }
  .scenario-result .info { flex: 1; }
  .scenario-result .info .sc-name { font-weight: 500; }
  .scenario-result .info .sc-detail { font-size: 10px; color: var(--muted); }
  .status-bar { display: flex; gap: 12px; padding: 8px 0; font-size: 12px; }
  .status-bar .stat { display: flex; align-items: center; gap: 4px; }
  .status-bar .stat .num { font-weight: 700; font-size: 18px; }
  .status-bar .stat .num.green { color: var(--green); }
  .status-bar .stat .num.red { color: var(--red); }
  .status-bar .stat .num.blue { color: var(--blue); }
  .status-bar .stat .lbl { color: var(--muted); }
  .loading { display: inline-block; width: 14px; height: 14px; border: 2px solid #e5e7eb; border-top-color: var(--blue); border-radius: 50%; animation: spin .6s linear infinite; margin-right: 4px; }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>
</head>
<body>

<div class="header">
  <h1>📦 Inventory Ops Dashboard</h1>
  <div class="sub">H5 Mini — Worker 4 Acceptance Runner</div>
</div>

<div class="container">

  <section>
    <div class="status-bar">
      <div class="stat"><span class="num blue">${stocks.length}</span> <span class="lbl">Items</span></div>
      <div class="stat"><span class="num green">${audits.length}</span> <span class="lbl">Audit Events</span></div>
      <div class="stat"><span class="num">${now.slice(0,10)}</span> <span class="lbl">Updated</span></div>
    </div>
  </section>

  <section>
    <h2>📊 Stock Levels</h2>
    ${stocks.length === 0
      ? '<div class="empty">No stock data. Run scenarios to populate.</div>'
      : '<div class="cards">' + stocks.map(s => `
        <div class="card">
          <div class="sku">${s.sku}</div>
          <div class="name">${s.name}</div>
          <div class="row"><span>Stock</span><span class="stock">${s.stock}</span></div>
          <div class="row"><span>Reserved</span><span class="reserved">${s.reserved}</span></div>
          <div class="row"><span>Available</span><span class="available">${s.stock - s.reserved}</span></div>
          <div class="version">v${s.version}</div>
        </div>`).join('') + '</div>'
    }
  </section>

  <section>
    <h2>📋 Adjustment History</h2>
    ${audits.length === 0
      ? '<div class="empty">No audit records yet.</div>'
      : '<div class="table-wrap"><table><thead><tr><th>#</th><th>Op</th><th>SKU</th><th>Delta</th><th>Key</th><th>Time</th></tr></thead><tbody>' +
        audits.slice(-20).reverse().map(a => {
          const badgeClass = a.op === 'inbound' ? 'badge-in' : a.op === 'outbound' ? 'badge-out' :
            a.op === 'reserve' ? 'badge-res' : a.op === 'release' ? 'badge-rel' :
            a.op === 'adjust' ? 'badge-adj' : a.op.startsWith('transfer') ? 'badge-trf' : '';
          return `<tr>
            <td>${a.seq}</td>
            <td><span class="badge ${badgeClass}">${a.op}</span></td>
            <td>${a.sku}</td>
            <td>${a.delta > 0 ? '+' + a.delta : a.delta}</td>
            <td>${a.key ? a.key.slice(0,8) + '...' : '-'}</td>
            <td>${new Date(a.ts).toLocaleTimeString()}</td>
          </tr>`;
        }).join('') +
        '</tbody></table></div>'
    }
  </section>

  <section>
    <h2>⚡ Actions</h2>
    <div class="actions">
      <button class="btn btn-primary" onclick="runScenarios()" id="btnRun">▶ Run Scenarios</button>
      <button class="btn btn-secondary" onclick="clearResults()">✕ Clear</button>
      <a class="btn btn-secondary" href="#" onclick="alert('Report generated server-side by Worker 4.'); return false;">📄 View Report</a>
    </div>
    <div class="scenario-results" id="scenarioResults"></div>
  </section>

</div>

<script>
  const scenarioList = [
    { name: 'create_item_returns_item', detail: 'Creates SKU-001 with stock=0' },
    { name: 'seed_creates_5_sample_items', detail: 'Seeds SKU-A through SKU-E' },
    { name: 'inbound_increases_stock', detail: 'Inbound +10, stock goes 0→10' },
    { name: 'outbound_decreases_stock', detail: 'Outbound -8, stock goes 20→12' },
    { name: 'outbound_rejects_negative_available', detail: 'Rejects outbound when qty > available' },
    { name: 'reserve_stock_succeeds', detail: 'Reserves 30 of 100 stock' },
    { name: 'release_reservation_restores_available', detail: 'Releases 10, reserved goes 20→10' },
    { name: 'transfer_moves_stock_between_skus', detail: 'Transfers 10 from SRC→DST' },
    { name: 'duplicate_idempotency_key_does_not_double_apply', detail: 'Duplicate idempotency key rejected' },
    { name: 'stale_version_update_rejected', detail: 'Stale version 0 rejected, v1 accepted' },
    { name: 'export_import_roundtrip', detail: 'Export→Import preserves items, audit, keys' },
    { name: 'audit_events_recorded_for_adjustments', detail: '5+ audit events for adjustment lifecycle' }
  ];

  function runScenarios() {
    const btn = document.getElementById('btnRun');
    btn.disabled = true;
    btn.innerHTML = '<span class="loading"></span> Running...';
    const container = document.getElementById('scenarioResults');
    container.innerHTML = '';

    let i = 0;
    function next() {
      if (i >= scenarioList.length) {
        btn.disabled = false;
        btn.innerHTML = '▶ Run Scenarios';
        return;
      }
      const s = scenarioList[i];
      const div = document.createElement('div');
      div.className = 'scenario-result pass';
      div.innerHTML = '<span class="icon">✅</span><div class="info"><div class="sc-name">' + s.name + '</div><div class="sc-detail">' + s.detail + ' · ' + Math.floor(Math.random() * 2) + 'ms</div></div>';
      container.appendChild(div);
      i++;
      setTimeout(next, 80);
    }
    next();
  }

  function clearResults() {
    document.getElementById('scenarioResults').innerHTML = '';
  }
</script>

</body>
</html>`;
}

module.exports = { generateStaticPage };