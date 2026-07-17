// persistence.js — JSON file persistence
// Node.js built-ins only.

const fs = require("fs");
const path = require("path");

/**
 * Save JSON-serializable state to a file.
 * @param {string} filepath - Absolute or relative path to the JSON file.
 * @param {object} data - The state object to persist.
 */
function saveState(filepath, data) {
  const dir = path.dirname(filepath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const json = JSON.stringify(data, null, 2);
  fs.writeFileSync(filepath, json, "utf-8");
}

/**
 * Load JSON state from a file.
 * @param {string} filepath - Absolute or relative path to the JSON file.
 * @returns {object} The parsed state object.
 */
function loadState(filepath) {
  if (!fs.existsSync(filepath)) {
    throw new Error(`State file not found: ${filepath}`);
  }
  const raw = fs.readFileSync(filepath, "utf-8");
  return JSON.parse(raw);
}

module.exports = { saveState, loadState };
