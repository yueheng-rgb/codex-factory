// cli.js — CLI for inventory operations
// Node.js built-ins only. Uses shared store + auto persistence via state file.

const store = require("./store");
const { seedSampleData } = require("./seedData");
const { saveState, loadState } = require("./persistence");
const path = require("path");

const DEFAULT_STATE_FILE = path.join(__dirname, ".inventory-state.json");

function autoLoad() {
  try {
    const data = loadState(DEFAULT_STATE_FILE);
    store.importState(data);
  } catch (err) {
    // No saved state yet — start fresh
  }
}

function autoSave() {
  try {
    saveState(DEFAULT_STATE_FILE, store.exportState());
  } catch (err) {
    process.stderr.write(`Warning: could not save state: ${err.message}\n`);
  }
}

function printJSON(data) {
  process.stdout.write(JSON.stringify(data, null, 2) + "\n");
}

function printUsage() {
  const help = [
    "Usage: node cli.js <command> [args...]",
    "",
    "Commands:",
    "  seed                        Create 5 sample items with stock",
    "  inbound <skuId> <qty>       Process inbound (add stock)",
    "  outbound <skuId> <qty>      Process outbound (remove stock)",
    "  export                      Print full state as JSON",
    "  report                      Print markdown inventory report",
    "",
    "Examples:",
    "  node cli.js seed",
    "  node cli.js inbound SKU-001 50",
    "  node cli.js outbound SKU-002 10",
    "  node cli.js export",
    "  node cli.js report",
  ].join("\n");
  process.stdout.write(help + "\n");
}

/**
 * Handle CLI arguments.
 * @param {string[]} argv - process.argv.slice(2)
 */
function handleCli(argv) {
  const cmd = argv[0];

  if (!cmd || cmd === "help" || cmd === "--help" || cmd === "-h") {
    printUsage();
    return;
  }

  // Load persisted state before executing command
  autoLoad();

  switch (cmd) {
    case "seed": {
      const results = seedSampleData();
      autoSave();
      printJSON(results);
      break;
    }

    case "inbound": {
      const skuId = argv[1];
      const qty = parseInt(argv[2], 10);
      if (!skuId || isNaN(qty)) {
        process.stderr.write("Usage: node cli.js inbound <skuId> <quantity>\n");
        process.exit(1);
      }
      try {
        const result = store.inbound(skuId, qty, null);
        autoSave();
        printJSON(result || { status: "idempotent" });
      } catch (err) {
        process.stderr.write(`Error: ${err.message}\n`);
        process.exit(1);
      }
      break;
    }

    case "outbound": {
      const skuId = argv[1];
      const qty = parseInt(argv[2], 10);
      if (!skuId || isNaN(qty)) {
        process.stderr.write("Usage: node cli.js outbound <skuId> <quantity>\n");
        process.exit(1);
      }
      try {
        const result = store.outbound(skuId, qty);
        autoSave();
        printJSON(result);
      } catch (err) {
        process.stderr.write(`Error: ${err.message}\n`);
        process.exit(1);
      }
      break;
    }

    case "export": {
      const data = store.exportState();
      printJSON(data);
      break;
    }

    case "report": {
      const md = store.generateReport();
      process.stdout.write(md + "\n");
      break;
    }

    default: {
      process.stderr.write(`Unknown command: ${cmd}\n`);
      printUsage();
      process.exit(1);
    }
  }
}

module.exports = { handleCli };

// ─── Direct Run ─────────────────────────────────────────────────────
if (require.main === module) {
  handleCli(process.argv.slice(2));
}
