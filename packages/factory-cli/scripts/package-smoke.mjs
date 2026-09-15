import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { appendFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const npmCli = process.env.npm_execpath;
assert.ok(npmCli && existsSync(npmCli), "Run this check with npm run test:package");
const manifest = JSON.parse(readFileSync(join(packageRoot, "package.json"), "utf8"));
const gitOptions = { cwd: packageRoot, encoding: "utf8", windowsHide: true, timeout: 10000 };
const revision = spawnSync("git", ["rev-parse", "HEAD"], gitOptions);
const status = spawnSync("git", ["status", "--porcelain", "--untracked-files=all"], gitOptions);
const sourceCommit = revision.status === 0 ? revision.stdout.trim() : null;
const sourceClean = status.status === 0 ? status.stdout.trim() === "" : null;
const smokeRoot = mkdtempSync(join(tmpdir(), "factory-package-smoke-"));
const consumerRoot = join(smokeRoot, "consumer project");
const projectRoot = join(smokeRoot, "target project");
mkdirSync(consumerRoot);
mkdirSync(projectRoot);
writeFileSync(join(consumerRoot, "package.json"), JSON.stringify({ private: true }), "utf8");
process.stdout.write("Package smoke artifacts: " + smokeRoot + "\n");

function npm(args, cwd) {
  const child = spawnSync(process.execPath, [npmCli, ...args], {
    cwd, encoding: "utf8", shell: false, windowsHide: true,
    timeout: 120000, maxBuffer: 4 * 1024 * 1024,
    env: { ...process.env, NODE_PATH: "", npm_config_offline: "true",
      npm_config_audit: "false", npm_config_fund: "false", npm_config_update_notifier: "false" },
  });
  assert.ifError(child.error);
  assert.equal(child.status, 0, "npm " + args.join(" ") + "\n" + child.stdout + child.stderr);
  return child.stdout.trim();
}

// Exercise npm's installed command shim, not the source tree or a tsx loader.
function cli(args) {
  return npm(["exec", "--offline", "--", "factoryctl", ...args], consumerRoot);
}

npm(["run", "build"], packageRoot);
const [packed] = JSON.parse(npm(["pack", "--json", "--pack-destination", smokeRoot], packageRoot));
assert.equal(packed.name, manifest.name);
assert.equal(packed.version, manifest.version);
const packedPaths = new Set(packed.files.map((file) => file.path));
assert.ok(packedPaths.has("dist/cli.js"), "Package must contain the compiled entry point");
assert.ok(packedPaths.has("examples/module-delivery.tasks.json"), "Package must contain task examples");
assert.equal([...packedPaths].filter((path) => /^domain-skills\/[^/]+\/SKILL\.md$/.test(path)).length, 9);
assert.ok(![...packedPaths].some((path) => /^(src|tests|scripts|node_modules)\//.test(path)));
const tarball = join(smokeRoot, packed.filename);
npm(["install", "--offline", "--ignore-scripts", "--omit=dev", "--no-audit", "--no-fund", tarball], consumerRoot);
const installedRoot = join(consumerRoot, "node_modules", "@codex-app-factory", "cli");
assert.ok(existsSync(join(installedRoot, "dist", "cli.js")));
assert.ok(existsSync(join(consumerRoot, "node_modules", ".bin",
  process.platform === "win32" ? "factoryctl.cmd" : "factoryctl")), "Local command shim must exist");
assert.ok(!existsSync(join(installedRoot, "node_modules", "tsx")));
assert.match(cli(["--help"]), /factoryctl init/);
assert.equal(cli(["version"]), manifest.version);

const initArgs = ["init", "--project", projectRoot, "--no-multi-agent", "--external-context", "--search", "none", "--json"];
const initialized = JSON.parse(cli(initArgs));
assert.deepEqual(initialized.warnings, []);
const agentsPath = join(projectRoot, "AGENTS.md");
const initialAgents = readFileSync(agentsPath, "utf8");
cli(initArgs);
assert.equal(readFileSync(agentsPath, "utf8"), initialAgents, "Repeat init must preserve managed rules");
const doctor = JSON.parse(cli(["doctor", "--project", projectRoot, "--json"]));
assert.ok(["READY", "READY_WITH_LIMITATIONS"].includes(doctor.status));
assert.ok(doctor.checks.length > 0);
assert.ok(doctor.checks.every((check) => check.status !== "FAIL"));
assert.equal(doctor.checks.find((check) => check.id === "external_context.ledger")?.status, "PASS");
for (const skillPath of [...packedPaths].filter((path) => /^domain-skills\/[^/]+\/SKILL\.md$/.test(path))) {
  const installedSkill = join(projectRoot, ".agents", "skills", skillPath.split("/")[1], "SKILL.md");
  assert.equal(readFileSync(installedSkill, "utf8"), readFileSync(join(installedRoot, skillPath), "utf8"));
}
const ledger = JSON.parse(cli(["context", "verify", "--project", projectRoot, "--json"]));
assert.equal(ledger.valid, true);

const report = {
  status: "PASS", package: packed.name, version: packed.version,
  source_commit: sourceCommit, source_worktree_clean: sourceClean,
  generated_at: new Date().toISOString(),
  node: process.version, platform: process.platform,
  tarball: packed.filename, sha256: createHash("sha256").update(readFileSync(tarball)).digest("hex"),
  packed_files: packed.files.length, doctor_status: doctor.status,
  checks: ["offline tarball install", "installed command shim", "help and version",
    "repeatable init", "nine bundled domain skills", "doctor", "SQLite context integrity"],
  limitations: ["No live agent execution, hook trust approval, or registry publication."],
};
writeFileSync(join(smokeRoot, "result.json"), JSON.stringify(report, null, 2) + "\n", "utf8");
if (process.env.GITHUB_OUTPUT) {
  appendFileSync(process.env.GITHUB_OUTPUT, "artifact_directory=" + smokeRoot + "\n", "utf8");
}
process.stdout.write(JSON.stringify(report, null, 2) + "\n");
