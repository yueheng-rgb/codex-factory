import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";
import { afterEach, describe, it } from "node:test";
import {
  parseCodexFeatureList,
  runDoctor,
  type CodexCapabilityProbe,
} from "../src/doctor.js";
import {
  AGENTS_BLOCK_START,
  initializeFactoryProject,
} from "../src/installer.js";

const temporaryRoots: string[] = [];
const TEST_CODEX_CAPABILITY: CodexCapabilityProbe = {
  available: true,
  version: "0.145.0",
  multi_agent: true,
  multi_agent_v2: false,
  hooks: true,
};

function testDoctor(root: string) {
  return runDoctor(root, { codexCapabilityProbe: () => TEST_CODEX_CAPABILITY });
}

function projectRoot(): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-installer-"));
  temporaryRoots.push(root);
  return root;
}

afterEach(() => {
  for (const root of temporaryRoots.splice(0)) {
    rmSync(root, { recursive: true, force: true });
  }
});

describe("initializeFactoryProject", () => {
  it("is repeatable and preserves user AGENTS.md content", () => {
    const root = projectRoot();
    writeFileSync(join(root, "AGENTS.md"), "# User rules\n\nKeep this line.\n", "utf8");

    const first = initializeFactoryProject(root, {
      multiAgent: true,
      externalContext: true,
      maxThreads: 4,
    });
    const second = initializeFactoryProject(root, {
      multiAgent: true,
      externalContext: true,
      maxThreads: 4,
    });

    assert.deepEqual(first.warnings, []);
    assert.deepEqual(second.warnings, []);
    const agents = readFileSync(join(root, "AGENTS.md"), "utf8");
    assert.match(agents, /Keep this line\./);
    assert.equal(agents.split(AGENTS_BLOCK_START).length, 2);
    assert.equal(
      existsSync(join(root, ".codex", "agents", "factory_verifier.toml")),
      true,
    );
    assert.equal(
      existsSync(join(root, ".agents", "skills", "codex-factory", "SKILL.md")),
      true,
    );
    const doctor = testDoctor(root);
    assert.equal(doctor.status, "READY_WITH_LIMITATIONS");
    assert.equal(
      doctor.checks.some(
        (check) => check.id === "multi_agent.isolation_strength" && check.status === "WARN",
      ),
      true,
    );
  });

  it("preserves an unowned Agent profile and fails closed", () => {
    const root = projectRoot();
    const agentDirectory = join(root, ".codex", "agents");
    mkdirSync(agentDirectory, { recursive: true });
    const path = join(agentDirectory, "factory_verifier.toml");
    writeFileSync(path, "name = \"user-verifier\"\n", "utf8");

    const initialized = initializeFactoryProject(root, { multiAgent: true });

    assert.equal(readFileSync(path, "utf8"), "name = \"user-verifier\"\n");
    assert.equal(
      initialized.warnings.some((warning) => warning.includes("unowned")),
      true,
    );
    const doctor = testDoctor(root);
    assert.equal(doctor.status, "NOT_READY");
    assert.equal(
      doctor.checks.find((check) => check.id === "multi_agent.agent_profiles")?.status,
      "FAIL",
    );
  });

  it("does not overwrite conflicting user-owned Codex limits", () => {
    const root = projectRoot();
    const codexDirectory = join(root, ".codex");
    mkdirSync(codexDirectory, { recursive: true });
    const path = join(codexDirectory, "config.toml");
    const userConfig = [
      "# user config",
      "[agents]",
      "max_threads = 2",
      "max_depth = 2",
      "keep_me = true",
      "",
    ].join("\n");
    writeFileSync(path, userConfig, "utf8");

    const initialized = initializeFactoryProject(root, {
      multiAgent: true,
      maxThreads: 4,
    });

    assert.equal(readFileSync(path, "utf8"), userConfig);
    assert.equal(
      initialized.warnings.some((warning) => warning.includes("conflict")),
      true,
    );
    assert.equal(testDoctor(root).status, "NOT_READY");
  });

  it("reports only credential presence when GLM search is enabled", () => {
    const root = projectRoot();
    const previous = process.env.ZHIPUAI_API_KEY;
    delete process.env.ZHIPUAI_API_KEY;
    try {
      initializeFactoryProject(root, { searchProvider: "glm_zhipu" });
      const missing = testDoctor(root);
      const check = missing.checks.find(
        (item) => item.id === "external_search.credential",
      );
      assert.equal(missing.status, "NOT_READY");
      assert.match(check?.detail ?? "", /present: false/);

      process.env.ZHIPUAI_API_KEY = "must-never-appear-in-doctor-output";
      const ready = testDoctor(root);
      const serialized = JSON.stringify(ready);
      assert.equal(ready.status, "READY_WITH_LIMITATIONS");
      assert.equal(serialized.includes("must-never-appear-in-doctor-output"), false);
      assert.match(serialized, /present: true/);
    } finally {
      if (previous === undefined) delete process.env.ZHIPUAI_API_KEY;
      else process.env.ZHIPUAI_API_KEY = previous;
    }
  });

  it("parses current Codex feature-list rows without trusting decorative columns", () => {
    const parsed = parseCodexFeatureList([
      "multi_agent stable true",
      "multi_agent_v2 under development false",
      "not-a-feature-row",
    ].join("\n"));
    assert.equal(parsed.get("multi_agent"), true);
    assert.equal(parsed.get("multi_agent_v2"), false);
  });

  it("fails readiness when Factory multi-agent is enabled but Codex lacks it", () => {
    const root = projectRoot();
    initializeFactoryProject(root, { multiAgent: true });
    const doctor = runDoctor(root, {
      codexCapabilityProbe: () => ({
        available: true,
        version: "0.140.0",
        multi_agent: false,
        multi_agent_v2: false,
        hooks: true,
      }),
    });
    assert.equal(doctor.status, "NOT_READY");
    assert.equal(
      doctor.checks.find((check) => check.id === "multi_agent.codex_capabilities")?.status,
      "FAIL",
    );
  });
});
