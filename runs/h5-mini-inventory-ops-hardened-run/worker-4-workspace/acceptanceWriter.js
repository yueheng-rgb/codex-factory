'use strict';

const fs = require('fs');
const path = require('path');

function writeAcceptanceReport(scenarios, outputDir) {
  const reportsDir = outputDir || path.join(__dirname, 'reports');
  if (!fs.existsSync(reportsDir)) fs.mkdirSync(reportsDir, { recursive: true });

  const report = {
    title: 'H5 Mini Inventory Ops — Acceptance Report',
    generatedAt: new Date().toISOString(),
    summary: {
      total: scenarios.length,
      passed: scenarios.filter(s => s.passed).length,
      failed: scenarios.filter(s => !s.passed).length,
      elapsedTotalMs: scenarios.reduce((sum, s) => sum + (s.elapsedMs || 0), 0)
    },
    scenarios: scenarios.map(s => ({
      name: s.name,
      passed: s.passed,
      details: s.details,
      elapsedMs: s.elapsedMs
    })),
    worker: 'worker-4',
    evidence: 'worker-4-evidence.json'
  };

  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = 'acceptance-' + ts + '.json';
  const filepath = path.join(reportsDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(report, null, 2), 'utf8');

  return { filepath, report };
}

module.exports = { writeAcceptanceReport };