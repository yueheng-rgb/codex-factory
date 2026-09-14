import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { parseJsonFileText, readJson, writeJsonAtomic } from "../src/util.js";
import { repairTask } from "./helpers/repair-fixture.js";

test("local JSON accepts one leading UTF-8 BOM without changing string content or the source file", (context) => {
  const root = mkdtempSync(join(tmpdir(), "factory-json-files-"));
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const path = join(root, "input.json");
  const expected = { value: "\uFEFFkeep\uFEFF", label: "\u4e2d\u6587", count: 0 };
  for (const prefix of ["", "\uFEFF"]) {
    const bytes = Buffer.from(prefix + JSON.stringify(expected) + "\r\n", "utf8");
    writeFileSync(path, bytes);
    assert.deepEqual(readJson(path), expected);
    assert.deepEqual(readFileSync(path), bytes);
  }
  writeJsonAtomic(path, expected);
  assert.notEqual(readFileSync(path, "utf8").charCodeAt(0), 0xfeff);
});

test("BOM compatibility does not accept broken JSON, repeated BOMs or alternate file encodings", (context) => {
  for (const value of ["\uFEFF", "\uFEFF\uFEFF{}", " \uFEFF{}", "{}\uFEFF", "\uFEFF{", "\uFEFF[1,]", "\uFEFF{ /* comment */ }"]) {
    assert.throws(() => parseJsonFileText(value), SyntaxError);
  }
  assert.equal(parseJsonFileText("\uFEFFnull"), null);
  assert.equal(parseJsonFileText("\uFEFFfalse"), false);
  const root = mkdtempSync(join(tmpdir(), "factory-json-encoding-"));
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const path = join(root, "utf16.json");
  writeFileSync(path, Buffer.from("\uFEFF{}", "utf16le"));
  assert.throws(() => readJson(path), SyntaxError);
});

test("the real task CLI accepts a BOM-bearing task file and still checks its task schema", (context) => {
  const root = mkdtempSync(join(tmpdir(), "factory-json-cli-"));
  context.after(() => rmSync(root, { recursive: true, force: true }));
  const path = join(root, "tasks.json");
  const cliPath = join(dirname(fileURLToPath(import.meta.url)), "../src/cli.ts");
  const run = () => spawnSync(process.execPath,
    ["--import", "tsx", cliPath, "tasks", "validate", "--project", root, "--tasks", "tasks.json", "--json"],
    { encoding: "utf8", windowsHide: true });
  writeFileSync(path, "\uFEFF" + JSON.stringify([repairTask()]));
  const original = readFileSync(path);
  const result = run();
  assert.equal(result.status, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout).worker_count, 1);
  assert.deepEqual(readFileSync(path), original);
  writeFileSync(path, '\uFEFF[{"task_id":"worker"}]');
  assert.equal(run().status, 1);
});
