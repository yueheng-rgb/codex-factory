import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  utimesSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";
import { getAgentProfile, profileForTaskRole } from "../src/agents.js";
import { initializeConfig } from "../src/config.js";
import {
  appendContextEvent,
  contextDatabasePath,
  createContextPacket,
  initializeContextSpace,
  verifyContextLedger,
  verifyContextPacket,
} from "../src/context-space.js";
import { recordAgentHandoff, verifyTaskCompletion } from "../src/evidence.js";
import {
  addAutomaticVerificationTasks,
  prepareSpawnPlan,
  readAgentRegistry,
  registerNativeDispatch,
  setRunTaskStatus,
  validateTaskGraph,
  writeScopesConflict,
} from "../src/orchestrator.js";
import type { ContextPacket, FactoryTask } from "../src/types.js";
import {
  assertWithinRoot,
  sha256,
  stableStringify,
  withFileLock,
} from "../src/util.js";

const temporaryRoots: string[] = [];

function createProject(options: { context?: boolean; maxThreads?: number } = {}): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-control-"));
  temporaryRoots.push(root);
  initializeConfig(root, {
    multiAgent: true,
    externalContext: options.context ?? true,
    maxThreads: options.maxThreads ?? 4,
  });
  if (options.context ?? true) initializeContextSpace(root);
  return root;
}

function factoryTask(
  taskId: string,
  overrides: Partial<FactoryTask> = {},
): FactoryTask {
  return {
    task_id: taskId,
    title: "Task " + taskId,
    description: "Execute the bounded task " + taskId,
    role: "implementation",
    status: "pending",
    dependencies: [],
    write_scope: ["src/" + taskId],
    acceptance_methods: ["exists:package.json"],
    required_artifacts: [],
    ...overrides,
  };
}

function rehashPacket(packet: ContextPacket): ContextPacket {
  const { packet_hash: _oldHash, ...unsigned } = packet;
  return {
    ...packet,
    packet_hash: sha256(stableStringify(unsigned)),
  };
}

function nativeReceipt(nativeAgentId: string, nickname = "Ampere"): Record<string, unknown> {
  return {
    tool_name: "spawn_agent",
    agent_id: nativeAgentId,
    native_agent_id: nativeAgentId,
    id: nativeAgentId,
    nickname,
    status: "spawned",
  };
}

function factoryCliPath(): string {
  return join(dirname(fileURLToPath(import.meta.url)), "..", "src", "cli.ts");
}

function runFactoryCli(arguments_: string[]): Promise<{
  code: number | null;
  stdout: string;
  stderr: string;
}> {
  return new Promise((resolvePromise, rejectPromise) => {
    const child = spawn(
      process.execPath,
      ["--import", "tsx", factoryCliPath(), ...arguments_],
      {
        cwd: join(dirname(factoryCliPath()), ".."),
        windowsHide: true,
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk: string) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk: string) => {
      stderr += chunk;
    });
    child.once("error", rejectPromise);
    child.once("close", (code) => resolvePromise({ code, stdout, stderr }));
  });
}

async function waitForPath(path: string, timeoutMs = 3_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (!existsSync(path)) {
    if (Date.now() >= deadline) throw new Error("Timed out waiting for path: " + path);
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 20));
  }
}

function persistedTasks(root: string, runId: string): FactoryTask[] {
  const graph = JSON.parse(
    readFileSync(join(root, ".codex-factory", "runs", runId, "task-graph.json"), "utf8"),
  ) as { tasks: FactoryTask[] };
  return graph.tasks;
}

function executeVerificationScenario(
  verifierProposal: "PASS" | "FAIL",
  verifierCommands: Array<{ command: string; exit_code: number }> = [],
): { root: string; runId: string; verdict: "PASS" | "FAIL" } {
  const root = createProject({ context: false, maxThreads: 4 });
  const runId = "run-verification-" + verifierProposal.toLowerCase();
  const initial = prepareSpawnPlan(
    root,
    [
      factoryTask("worker", {
        write_scope: ["artifact.txt"],
        required_artifacts: ["artifact.txt"],
        acceptance_methods: ["exists:artifact.txt"],
      }),
    ],
    runId,
  );
  const worker = initial.assignments.find((assignment) => assignment.task_id === "worker");
  assert.ok(worker);
  registerNativeDispatch(root, runId, worker.assignment_id, {
    nativeAgentId: "native-worker-" + verifierProposal.toLowerCase(),
    rawToolReceipt: nativeReceipt("native-worker-" + verifierProposal.toLowerCase()),
    toolName: "spawn_agent",
  });
  writeFileSync(join(root, "artifact.txt"), "worker output\n", "utf8");
  recordAgentHandoff(root, runId, worker.assignment_id, {
    summary: "Worker handoff awaiting independent verification.",
    changed_paths: ["artifact.txt"],
    artifacts: [
      { path: "artifact.txt", sha256: sha256(readFileSync(join(root, "artifact.txt"))) },
    ],
    commands: [],
    proposed_verdict: "PASS",
  });

  const authoritativeTasks = persistedTasks(root, runId);
  assert.deepEqual(addAutomaticVerificationTasks(authoritativeTasks), authoritativeTasks);
  const verifierWave = prepareSpawnPlan(root, authoritativeTasks, runId);
  const verifier = verifierWave.assignments.find(
    (assignment) => assignment.profile_id === "factory_verifier",
  );
  assert.ok(verifier);
  registerNativeDispatch(root, runId, verifier.assignment_id, {
    nativeAgentId: "native-verifier-" + verifierProposal.toLowerCase(),
    rawToolReceipt: nativeReceipt(
      "native-verifier-" + verifierProposal.toLowerCase(),
      "Feynman",
    ),
    toolName: "spawn_agent",
  });
  recordAgentHandoff(root, runId, verifier.assignment_id, {
    summary: "Independent verifier completed its review.",
    changed_paths: [],
    artifacts: [],
    commands: verifierCommands,
    proposed_verdict: verifierProposal,
  });
  const receipt = verifyTaskCompletion(root, runId, "worker", verifier.assignment_id);
  return { root, runId, verdict: receipt.verdict };
}

afterEach(() => {
  for (const root of temporaryRoots.splice(0)) {
    rmSync(root, { recursive: true, force: true });
  }
});

describe("external Context Space", () => {
  it("rejects a tampered SQLite hash chain and refuses another append", () => {
    const root = createProject();
    appendContextEvent(root, "requirement", "main_controller", {
      requirement: "keep the ledger authoritative",
    });

    const database = new DatabaseSync(contextDatabasePath(root));
    try {
      database
        .prepare("UPDATE context_events SET payload_json = ? WHERE sequence = 1")
        .run('{"requirement":"tampered"}');
    } finally {
      database.close();
    }

    const verification = verifyContextLedger(root);
    assert.equal(verification.valid, false);
    assert.match(verification.issues.join("\n"), /hash mismatch/i);
    assert.throws(
      () => appendContextEvent(root, "decision", "main_controller", { decision: "must fail" }),
      /ledger is invalid/i,
    );
  });

  it("detects silent deletion of the ledger tail and matching FTS row", () => {
    const root = createProject();
    appendContextEvent(root, "requirement", "main_controller", { sequence: 1 });
    const tail = appendContextEvent(root, "decision", "main_controller", { sequence: 2 });

    const database = new DatabaseSync(contextDatabasePath(root));
    try {
      database.prepare("DELETE FROM context_events_fts WHERE event_id = ?").run(tail.event_id);
      database.prepare("DELETE FROM context_event_admissions WHERE event_id = ?").run(tail.event_id);
      database.prepare("DELETE FROM context_events WHERE event_id = ?").run(tail.event_id);
    } finally {
      database.close();
    }

    const verification = verifyContextLedger(root);
    assert.equal(verification.valid, false);
    assert.match(verification.issues.join("\n"), /head|count|anchor|delet|metadata/i);
    assert.throws(
      () => appendContextEvent(root, "risk", "main_controller", { risk: "must not fork" }),
      /ledger is invalid|anchor|head|count/i,
    );
  });

  it("rejects context metadata bound to a different project", () => {
    const root = createProject();
    appendContextEvent(root, "requirement", "main_controller", {
      requirement: "must remain project-scoped",
    });
    const database = new DatabaseSync(contextDatabasePath(root));
    try {
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'project_id'")
        .run("different-project");
    } finally {
      database.close();
    }

    const verification = verifyContextLedger(root);
    assert.equal(verification.valid, false);
    assert.match(verification.issues.join("\n"), /project/i);
  });

  it("keeps frontend summaries untrusted and filters role-private events", () => {
    const root = createProject();
    const privateEvent = appendContextEvent(root, "decision", "main_controller", {
      decision: "librarian only",
      visible_to_roles: ["librarian"],
    });
    const publicEvent = appendContextEvent(root, "requirement", "main_controller", {
      requirement: "public requirement",
    });
    const frontendEvent = appendContextEvent(root, "frontend_summary", "codex_frontend", {
      summary: "this text must never become trusted evidence",
      visible_to_roles: ["verifier"],
    });

    const { packet } = createContextPacket(root, "run-role-isolation", "verifier");

    assert.equal(packet.source_event_ids.includes(privateEvent.event_id), false);
    assert.equal(packet.source_event_ids.includes(publicEvent.event_id), true);
    assert.equal(packet.source_event_ids.includes(frontendEvent.event_id), true);
    assert.equal(
      packet.trusted_context.some((event) => event.event_id === frontendEvent.event_id),
      false,
    );
    assert.equal(
      packet.untrusted_frontend_notes.some((event) => event.event_id === frontendEvent.event_id),
      true,
    );
    assert.deepEqual(verifyContextPacket(root, packet), {
      valid: true,
      stale: false,
      issues: [],
    });
  });

  it("rejects a rehashed packet that promotes a cross-role event", () => {
    const root = createProject();
    const privateEvent = appendContextEvent(root, "decision", "main_controller", {
      decision: "librarian only",
      visible_to_roles: ["librarian"],
    });
    const { packet } = createContextPacket(root, "run-forged-role", "verifier");
    const forged = structuredClone(packet);
    forged.source_event_ids.push(privateEvent.event_id);
    forged.trusted_context.push({
      event_id: privateEvent.event_id,
      kind: "decision",
      payload: privateEvent.payload,
    });

    const result = verifyContextPacket(root, rehashPacket(forged));
    assert.equal(result.valid, false);
    assert.match(result.issues.join("\n"), /role|visible|source|content/i);
  });

  it("rejects malformed expiry even when the packet hash is recomputed", () => {
    const root = createProject();
    appendContextEvent(root, "requirement", "main_controller", { requirement: "bounded" });
    const { packet } = createContextPacket(root, "run-invalid-expiry", "verifier");
    const forged = structuredClone(packet);
    forged.expires_at = "not-a-date";

    const result = verifyContextPacket(root, rehashPacket(forged));
    assert.equal(result.valid, false);
    assert.match(result.issues.join("\n"), /expir|date|timestamp/i);
  });

  it("keeps an immutable packet valid when later operational events extend the ledger", () => {
    const root = createProject();
    appendContextEvent(root, "requirement", "main_controller", {
      requirement: "assignment snapshot",
      visible_to_roles: ["verifier"],
    });
    const { packet } = createContextPacket(root, "run-ledger-ancestor", "verifier");
    appendContextEvent(root, "agent_event", "main_controller", {
      lifecycle: "spawned",
      visible_to_roles: ["main_controller"],
    });

    const result = verifyContextPacket(root, packet, {
      runId: "run-ledger-ancestor",
      targetRole: "verifier",
    });
    assert.equal(result.valid, true, result.issues.join("; "));
  });
});

describe("task DAG and scheduling", () => {
  it("routes the canonical verifier role to the independent resident verifier", () => {
    const profile = profileForTaskRole("verifier");
    assert.equal(profile.profile_id, "factory_verifier");
    assert.equal(profile.kind, "resident");
    assert.equal(profile.read_only, true);
  });

  it("rejects missing dependencies and cycles", () => {
    assert.throws(
      () => validateTaskGraph([factoryTask("a", { dependencies: ["missing"] })]),
      /missing dependency/i,
    );
    assert.throws(
      () =>
        validateTaskGraph([
          factoryTask("a", { dependencies: ["b"] }),
          factoryTask("b", { dependencies: ["a"] }),
        ]),
      /cycle/i,
    );
  });

  it("rejects parent traversal and canonicalizes benign write-scope spelling", () => {
    assert.throws(
      () => writeScopesConflict(["src/../shared"], ["shared"]),
      /scope|escape|parent|relative/i,
    );
    assert.equal(writeScopesConflict(["src//feature"], ["src/feature"]), true);
    assert.equal(writeScopesConflict(["src/a"], ["src/b"]), false);
  });

  it("does not accept caller-supplied verified status as evidence", () => {
    const root = createProject();
    const forgedTasks = [
      factoryTask("forged-complete", { status: "verified" }),
      factoryTask("downstream", { dependencies: ["forged-complete"] }),
    ];

    assert.throws(
      () => prepareSpawnPlan(root, forgedTasks, "run-forged-completed"),
      /verified|initial status|evidence|runtime state/i,
    );
  });

  it("does not create duplicate resident instances in one dispatch wave", () => {
    const root = createProject();
    const tasks = [
      factoryTask("route-a", { role: "router", write_scope: [] }),
      factoryTask("route-b", { role: "router", write_scope: [] }),
    ];

    const plan = prepareSpawnPlan(root, tasks, "run-resident-singleton");
    const residentKeys = plan.assignments
      .filter((assignment) => assignment.profile_kind === "resident")
      .map((assignment) => assignment.instance_key);
    assert.equal(new Set(residentKeys).size, residentKeys.length);
    assert.equal(
      readAgentRegistry(root, plan.run_id).entries.filter(
        (entry) => entry.instance_key === "resident:factory_router",
      ).length,
      1,
    );
  });

  it("refuses to orphan a planned wave by replanning before native dispatch", () => {
    const root = createProject({ context: false, maxThreads: 3 });
    const runId = "run-premature-replan";
    const first = prepareSpawnPlan(
      root,
      [factoryTask("a"), factoryTask("b"), factoryTask("c")],
      runId,
    );
    assert.equal(first.assignments.length, 2);

    const resumed = prepareSpawnPlan(root, persistedTasks(root, runId), runId);
    assert.deepEqual(
      resumed.assignments.map((assignment) => assignment.assignment_id).sort(),
      first.assignments.map((assignment) => assignment.assignment_id).sort(),
    );
    assert.equal(
      resumed.assignments.some((assignment) => assignment.task_id === "c"),
      false,
    );

    const assignment = first.assignments[0]!;
    assert.doesNotThrow(() =>
      registerNativeDispatch(root, runId, assignment.assignment_id, {
        nativeAgentId: "native-preserved-wave",
        rawToolReceipt: nativeReceipt("native-preserved-wave"),
        toolName: "spawn_agent",
      }),
    );
  });

  it("parallelizes disjoint scopes and blocks overlapping scopes", () => {
    const disjointRoot = createProject({ context: false, maxThreads: 4 });
    const disjoint = prepareSpawnPlan(
      disjointRoot,
      [factoryTask("a", { write_scope: ["src/a"] }), factoryTask("b", { write_scope: ["src/b"] })],
      "run-disjoint",
    );
    assert.deepEqual(
      disjoint.assignments.map((assignment) => assignment.task_id).sort(),
      ["a", "b"],
    );

    const overlapRoot = createProject({ context: false, maxThreads: 4 });
    const overlap = prepareSpawnPlan(
      overlapRoot,
      [
        factoryTask("parent", { write_scope: ["src/shared"] }),
        factoryTask("child", { write_scope: ["src/shared/child"] }),
      ],
      "run-overlap",
    );
    assert.equal(overlap.assignments.length, 1);
    assert.match(overlap.blocked_tasks[0]?.blocked_by.join(" ") ?? "", /scope:/);
  });

  it("returns a plan whose every Context Packet is still current", () => {
    const root = createProject({ context: true, maxThreads: 4 });
    const plan = prepareSpawnPlan(
      root,
      [factoryTask("packet-a"), factoryTask("packet-b")],
      "run-current-packets",
    );
    assert.equal(plan.assignments.length, 2);

    for (const assignment of plan.assignments) {
      const packet = JSON.parse(
        readFileSync(join(root, assignment.context_packet_path), "utf8"),
      ) as ContextPacket;
      const result = verifyContextPacket(root, packet, {
        runId: plan.run_id,
        targetRole: getAgentProfile(assignment.profile_id).role,
      });
      assert.equal(
        result.valid,
        true,
        assignment.task_id + ": " + result.issues.join("; "),
      );
    }
  });

  it("does not let an unrelated role-private event block assignment planning", () => {
    const root = createProject({ context: true });
    const privateEvent = appendContextEvent(root, "decision", "main_controller", {
      decision: "Only the librarian may receive this note.",
      visible_to_roles: ["librarian"],
    });

    const plan = prepareSpawnPlan(
      root,
      [factoryTask("implementation-with-private-history")],
      "run-private-history",
    );
    const assignment = plan.assignments.find(
      (item) => item.task_id === "implementation-with-private-history",
    );
    assert.ok(assignment);
    const packet = JSON.parse(
      readFileSync(join(root, assignment.context_packet_path), "utf8"),
    ) as ContextPacket;
    assert.equal(packet.source_event_ids.includes(privateEvent.event_id), false);
    assert.equal(
      verifyContextPacket(root, packet, {
        runId: plan.run_id,
        targetRole: "implementation",
        assignmentId: assignment.assignment_id,
      }).valid,
      true,
    );
  });

  it("detects task-graph tampering before a status transition", () => {
    const root = createProject({ context: false });
    const plan = prepareSpawnPlan(root, [factoryTask("tamper")], "run-graph-tamper");
    const graphPath = join(root, ".codex-factory", "runs", plan.run_id, "task-graph.json");
    const graph = JSON.parse(readFileSync(graphPath, "utf8")) as {
      tasks: Array<Record<string, unknown>>;
    };
    graph.tasks[0]!.title = "tampered without updating graph_sha256";
    writeFileSync(graphPath, JSON.stringify(graph, null, 2) + "\n", "utf8");

    assert.throws(
      () => setRunTaskStatus(root, plan.run_id, "tamper", "in_progress"),
      /hash|integrity|tamper/i,
    );
  });
});

describe("native dispatch and evidence gates", () => {
  it("rejects an empty self-authored native receipt", () => {
    const root = createProject({ context: false });
    const plan = prepareSpawnPlan(root, [factoryTask("receipt")], "run-empty-receipt");
    const assignment = plan.assignments.find((item) => item.task_id === "receipt");
    assert.ok(assignment);

    assert.throws(
      () =>
        registerNativeDispatch(root, plan.run_id, assignment.assignment_id, {
          nativeAgentId: "native-worker-empty",
          rawToolReceipt: {},
          toolName: "spawn_agent",
        }),
      /receipt|agent id|tool/i,
    );
  });

  it("rejects a followup receipt for an assignment planned as spawn", () => {
    const root = createProject({ context: false });
    const plan = prepareSpawnPlan(root, [factoryTask("wrong-tool")], "run-wrong-tool");
    const assignment = plan.assignments.find((item) => item.task_id === "wrong-tool");
    assert.ok(assignment);
    assert.equal(assignment.action, "spawn");

    assert.throws(
      () =>
        registerNativeDispatch(root, plan.run_id, assignment.assignment_id, {
          nativeAgentId: "native-worker-wrong-tool",
          rawToolReceipt: nativeReceipt("native-worker-wrong-tool"),
          toolName: "followup_task",
        }),
      /action|followup|spawn|tool/i,
    );
  });

  it("does not promote an unverified worker handoff to completed", () => {
    const root = createProject({ context: false });
    writeFileSync(join(root, "artifact.txt"), "verified later\n", "utf8");
    const plan = prepareSpawnPlan(
      root,
      [
        factoryTask("worker", {
          write_scope: ["artifact.txt"],
          required_artifacts: ["artifact.txt"],
          acceptance_methods: ["exists:artifact.txt"],
        }),
      ],
      "run-unverified-handoff",
    );
    const assignment = plan.assignments.find((item) => item.task_id === "worker");
    assert.ok(assignment);
    registerNativeDispatch(root, plan.run_id, assignment.assignment_id, {
      nativeAgentId: "native-worker-handoff",
      nativeNickname: "Ampere",
      rawToolReceipt: nativeReceipt("native-worker-handoff"),
      toolName: "spawn_agent",
    });
    const artifactHash = sha256(readFileSync(join(root, "artifact.txt")));

    recordAgentHandoff(root, plan.run_id, assignment.assignment_id, {
      summary: "Worker finished; independent verification is still required.",
      changed_paths: [],
      artifacts: [{ path: "artifact.txt", sha256: artifactHash }],
      commands: [],
      proposed_verdict: "PASS",
    });

    const graph = JSON.parse(
      readFileSync(join(root, ".codex-factory", "runs", plan.run_id, "task-graph.json"), "utf8"),
    ) as { tasks: FactoryTask[] };
    const worker = graph.tasks.find((task) => task.task_id === "worker");
    assert.notEqual(worker?.status, "completed");
  });

  it("rejects an omitted out-of-scope modification using the physical baseline", () => {
    const root = createProject({ context: false });
    writeFileSync(join(root, "allowed.txt"), "before allowed\n", "utf8");
    writeFileSync(join(root, "outside.txt"), "before outside\n", "utf8");
    const plan = prepareSpawnPlan(
      root,
      [
        factoryTask("scope-worker", {
          write_scope: ["allowed.txt"],
          required_artifacts: ["allowed.txt"],
          acceptance_methods: ["exists:allowed.txt"],
        }),
      ],
      "run-scope-baseline",
    );
    const assignment = plan.assignments.find((item) => item.task_id === "scope-worker");
    assert.ok(assignment);
    registerNativeDispatch(root, plan.run_id, assignment.assignment_id, {
      nativeAgentId: "native-worker-scope",
      rawToolReceipt: nativeReceipt("native-worker-scope"),
      toolName: "spawn_agent",
    });
    writeFileSync(join(root, "allowed.txt"), "after allowed\n", "utf8");
    writeFileSync(join(root, "outside.txt"), "after outside\n", "utf8");
    const allowedHash = sha256(readFileSync(join(root, "allowed.txt")));

    assert.throws(
      () =>
        recordAgentHandoff(root, plan.run_id, assignment.assignment_id, {
          summary: "Only the allowed change is self-reported.",
          changed_paths: ["allowed.txt"],
          artifacts: [{ path: "allowed.txt", sha256: allowedHash }],
          commands: [],
          proposed_verdict: "PASS",
        }),
      /outside|scope|baseline|unreported|diff/i,
    );
  });

  it("resumes cleanly after a complete independently verified PASS", () => {
    const scenario = executeVerificationScenario("PASS");
    assert.equal(scenario.verdict, "PASS");
    const resumed = prepareSpawnPlan(
      scenario.root,
      persistedTasks(scenario.root, scenario.runId),
      scenario.runId,
    );
    assert.deepEqual(resumed.assignments, []);
  });

  it("preserves a verifier-completed FAIL without treating the target as verified", () => {
    const scenario = executeVerificationScenario("FAIL");
    assert.equal(scenario.verdict, "FAIL");
    const graph = persistedTasks(scenario.root, scenario.runId);
    assert.equal(graph.find((task) => task.task_id === "worker")?.status, "failed");
    assert.doesNotThrow(() =>
      prepareSpawnPlan(scenario.root, graph, scenario.runId),
    );
  });

  it("fails closed on a verifier command failure and binds that handoff into the receipt", () => {
    const scenario = executeVerificationScenario("PASS", [
      { command: "npm test", exit_code: 1 },
    ]);
    assert.equal(scenario.verdict, "FAIL");

    const receipt = JSON.parse(
      readFileSync(
        join(
          scenario.root,
          ".codex-factory",
          "runs",
          scenario.runId,
          "verification",
          "worker",
          "receipt.json",
        ),
        "utf8",
      ),
    ) as {
      verifier_assignment_id: string;
      verifier_handoff_hash: string;
      failure_reasons: string[];
    };
    const verifierHandoff = JSON.parse(
      readFileSync(
        join(
          scenario.root,
          ".codex-factory",
          "runs",
          scenario.runId,
          "handoffs",
          receipt.verifier_assignment_id + ".json",
        ),
        "utf8",
      ),
    ) as { handoff_hash: string };

    assert.equal(receipt.verifier_handoff_hash, verifierHandoff.handoff_hash);
    assert.match(receipt.failure_reasons.join("\n"), /verifier.*failing command/i);
    assert.doesNotThrow(() =>
      prepareSpawnPlan(
        scenario.root,
        persistedTasks(scenario.root, scenario.runId),
        scenario.runId,
      ),
    );
  });

  it("rejects a rehashed worker or verifier handoff after a PASS receipt was issued", () => {
    for (const assignmentField of [
      "worker_assignment_id",
      "verifier_assignment_id",
    ] as const) {
      const scenario = executeVerificationScenario("PASS");
      const receipt = JSON.parse(
        readFileSync(
          join(
            scenario.root,
            ".codex-factory",
            "runs",
            scenario.runId,
            "verification",
            "worker",
            "receipt.json",
          ),
          "utf8",
        ),
      ) as Record<(typeof assignmentField), string>;
      const handoffPath = join(
        scenario.root,
        ".codex-factory",
        "runs",
        scenario.runId,
        "handoffs",
        receipt[assignmentField] + ".json",
      );
      const handoff = JSON.parse(readFileSync(handoffPath, "utf8")) as {
        report: { summary: string };
        handoff_hash: string;
        [key: string]: unknown;
      };
      handoff.report.summary += " Tampered after verification.";
      const { handoff_hash: _oldHash, ...unsigned } = handoff;
      handoff.handoff_hash = sha256(stableStringify(unsigned));
      writeFileSync(handoffPath, JSON.stringify(handoff, null, 2) + "\n", "utf8");

      assert.throws(
        () =>
          prepareSpawnPlan(
            scenario.root,
            persistedTasks(scenario.root, scenario.runId),
            scenario.runId,
          ),
        /handoff|receipt|hash|binding|integrity|tamper/i,
        assignmentField + " tampering must invalidate the persisted PASS",
      );
    }
  });

  it("keeps finalized handoffs and verification receipts immutable on retry", () => {
    const scenario = executeVerificationScenario("PASS");
    const receiptPath = join(
      scenario.root,
      ".codex-factory",
      "runs",
      scenario.runId,
      "verification",
      "worker",
      "receipt.json",
    );
    const receiptBytes = readFileSync(receiptPath, "utf8");
    const receipt = JSON.parse(receiptBytes) as {
      worker_assignment_id: string;
      verifier_assignment_id: string;
    };
    const workerHandoffPath = join(
      scenario.root,
      ".codex-factory",
      "runs",
      scenario.runId,
      "handoffs",
      receipt.worker_assignment_id + ".json",
    );
    const workerHandoffBytes = readFileSync(workerHandoffPath, "utf8");

    assert.throws(
      () =>
        recordAgentHandoff(
          scenario.root,
          scenario.runId,
          receipt.worker_assignment_id,
          {
            summary: "A late replacement must not overwrite finalized evidence.",
            changed_paths: ["artifact.txt"],
            artifacts: [
              {
                path: "artifact.txt",
                sha256: sha256(readFileSync(join(scenario.root, "artifact.txt"))),
              },
            ],
            commands: [],
            proposed_verdict: "PASS",
          },
        ),
      /handoff.*assigned|in-progress|immutable|current state/i,
    );
    assert.equal(readFileSync(workerHandoffPath, "utf8"), workerHandoffBytes);

    assert.throws(
      () =>
        verifyTaskCompletion(
          scenario.root,
          scenario.runId,
          "worker",
          receipt.verifier_assignment_id,
        ),
      /verification.*handoff|immutable|current state/i,
    );
    assert.equal(readFileSync(receiptPath, "utf8"), receiptBytes);
  });

  it("preserves every registry receipt and handoff under concurrent CLI writers", async () => {
    const root = createProject({ context: false, maxThreads: 8 });
    const tasks = Array.from({ length: 6 }, (_unused, index) => {
      const artifact = "artifacts/concurrent-" + index + ".txt";
      return factoryTask("concurrent-" + index, {
        write_scope: [artifact],
        required_artifacts: [artifact],
        acceptance_methods: ["exists:" + artifact],
      });
    });
    const runId = "run-concurrent-writers";
    const plan = prepareSpawnPlan(root, tasks, runId);
    assert.equal(plan.assignments.length, tasks.length);

    const registrations = await Promise.all(
      plan.assignments.map((assignment, index) => {
        const nativeId = "native-concurrent-" + index;
        return runFactoryCli([
          "agent",
          "register-spawn",
          "--project",
          root,
          "--run",
          runId,
          "--assignment",
          assignment.assignment_id,
          "--native-id",
          nativeId,
          "--receipt-json",
          JSON.stringify(nativeReceipt(nativeId)),
        ]);
      }),
    );
    for (const result of registrations) {
      assert.equal(result.code, 0, result.stderr || result.stdout);
    }

    const artifactDirectory = join(root, "artifacts");
    const handoffInputDirectory = join(root, ".codex-factory", "handoff-inputs");
    mkdirSync(artifactDirectory, { recursive: true });
    mkdirSync(handoffInputDirectory, { recursive: true });
    const handoffFiles = new Map<string, string>();
    for (const [index, assignment] of plan.assignments.entries()) {
      const artifact = "artifacts/concurrent-" + index + ".txt";
      writeFileSync(join(root, artifact), "concurrent output " + index + "\n", "utf8");
      const inputPath = join(handoffInputDirectory, assignment.assignment_id + ".json");
      writeFileSync(
        inputPath,
        JSON.stringify(
          {
            summary: "Concurrent worker " + index + " completed its bounded write.",
            changed_paths: [artifact],
            artifacts: [
              { path: artifact, sha256: sha256(readFileSync(join(root, artifact))) },
            ],
            commands: [],
            proposed_verdict: "PASS",
          },
          null,
          2,
        ) + "\n",
        "utf8",
      );
      handoffFiles.set(assignment.assignment_id, inputPath);
    }

    const handoffs = await Promise.all(
      plan.assignments.map((assignment) =>
        runFactoryCli([
          "handoff",
          "record",
          "--project",
          root,
          "--run",
          runId,
          "--assignment",
          assignment.assignment_id,
          "--file",
          handoffFiles.get(assignment.assignment_id)!,
        ]),
      ),
    );
    for (const result of handoffs) {
      assert.equal(result.code, 0, result.stderr || result.stdout);
    }

    const registry = readAgentRegistry(root, runId);
    assert.equal(registry.entries.length, tasks.length);
    assert.equal(
      registry.entries.every(
        (entry) => entry.native_agent_id && entry.native_receipts.length === 1,
      ),
      true,
    );
    assert.equal(
      persistedTasks(root, runId)
        .filter((task) => !task.task_id.startsWith("verify-"))
        .every((task) => task.status === "handoff"),
      true,
    );
  });

  it("reuses an idle resident by followup after its bounded handoff", () => {
    const root = createProject({ context: false, maxThreads: 4 });
    const runId = "run-resident-reuse";
    const plan = prepareSpawnPlan(
      root,
      [
        factoryTask("route-first", { role: "router", write_scope: [] }),
        factoryTask("route-second", { role: "router", write_scope: [] }),
      ],
      runId,
    );
    const first = plan.assignments.find((assignment) => assignment.task_id === "route-first");
    assert.ok(first);
    assert.equal(first.action, "spawn");
    registerNativeDispatch(root, runId, first.assignment_id, {
      nativeAgentId: "native-resident-router",
      rawToolReceipt: nativeReceipt("native-resident-router", "Atlas"),
      toolName: "spawn_agent",
    });
    recordAgentHandoff(root, runId, first.assignment_id, {
      summary: "Resident router completed the first bounded routing task.",
      changed_paths: [],
      artifacts: [],
      commands: [],
      proposed_verdict: "PASS",
    });

    const next = prepareSpawnPlan(root, persistedTasks(root, runId), runId);
    const reused = next.assignments.find(
      (assignment) => assignment.task_id === "route-second",
    );
    assert.ok(reused);
    assert.equal(reused.action, "followup");
    assert.equal(reused.reuse_native_agent_id, "native-resident-router");

    assert.throws(
      () =>
        recordAgentHandoff(root, runId, reused.assignment_id, {
          summary: "A reused resident must not inherit the prior assignment receipt.",
          changed_paths: [],
          artifacts: [],
          commands: [],
          proposed_verdict: "PASS",
        }),
      /assignment.*native tool receipt/i,
    );
    assert.throws(
      () => verifyTaskCompletion(root, runId, "route-second", "not-a-verifier"),
      /no native worker assignment/i,
    );
  });

  it("creates an independent verification path for a read-only resident output", () => {
    const root = createProject({ context: false, maxThreads: 4 });
    writeFileSync(join(root, "package.json"), "{}\n", "utf8");
    const runId = "run-read-only-verification";
    const plan = prepareSpawnPlan(
      root,
      [
        factoryTask("route-contract", {
          role: "router",
          write_scope: [],
          acceptance_methods: ["json:package.json"],
        }),
        factoryTask("implementation-after-route", {
          dependencies: ["route-contract"],
        }),
      ],
      runId,
    );
    const router = plan.assignments.find(
      (assignment) => assignment.task_id === "route-contract",
    );
    assert.ok(router);
    registerNativeDispatch(root, runId, router.assignment_id, {
      nativeAgentId: "native-router-to-verify",
      rawToolReceipt: nativeReceipt("native-router-to-verify", "Atlas"),
      toolName: "spawn_agent",
    });
    recordAgentHandoff(root, runId, router.assignment_id, {
      summary: "Routing contract is ready for independent review.",
      changed_paths: [],
      artifacts: [],
      commands: [],
      proposed_verdict: "PASS",
    });

    const verificationWave = prepareSpawnPlan(root, persistedTasks(root, runId), runId);
    const verifier = verificationWave.assignments.find(
      (assignment) => assignment.profile_id === "factory_verifier",
    );
    assert.ok(verifier);
    assert.equal(
      persistedTasks(root, runId).find(
        (task) => task.task_id === verifier.task_id,
      )?.dependencies.includes("route-contract"),
      true,
    );
    assert.equal(
      verificationWave.assignments.some(
        (assignment) => assignment.task_id === "implementation-after-route",
      ),
      false,
    );
  });
});

describe("CLI contract", () => {
  it("fails on an unknown flag instead of silently applying defaults", () => {
    const root = createProject({ context: false });
    const result = spawnSync(
      process.execPath,
      ["--import", "tsx", factoryCliPath(), "configure", "--project", root, "--multiagent"],
      { encoding: "utf8", windowsHide: true },
    );

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /unknown|multiagent|flag/i);
  });

  it("rejects a run id that attempts path traversal", () => {
    const root = createProject({ context: false });
    assert.throws(
      () => prepareSpawnPlan(root, [factoryTask("safe")], "../escape"),
      /invalid run id/i,
    );
    assert.equal(existsSync(join(root, "escape")), false);
  });

  it("rejects a project-internal junction that resolves outside the project", () => {
    const root = createProject({ context: false });
    const outside = mkdtempSync(join(tmpdir(), "codex-factory-outside-"));
    temporaryRoots.push(outside);
    writeFileSync(join(outside, "outside.json"), "{}\n", "utf8");
    const junction = join(root, "external-link");
    symlinkSync(outside, junction, "junction");

    assert.throws(
      () => assertWithinRoot(root, join(junction, "outside.json")),
      /escape|outside|symlink|junction|real path/i,
    );
  });

  it("verifies a packet through the CLI and rejects wrong assignment binding", () => {
    const root = createProject({ context: true });
    const plan = prepareSpawnPlan(root, [factoryTask("packet-cli")], "run-packet-cli");
    const assignment = plan.assignments.find((item) => item.task_id === "packet-cli");
    assert.ok(assignment);
    const role = getAgentProfile(assignment.profile_id).role;
    const baseArguments = [
      "--import",
      "tsx",
      factoryCliPath(),
      "context",
      "packet-verify",
      "--project",
      root,
      "--file",
      assignment.context_packet_path,
      "--run",
      plan.run_id,
      "--role",
      role,
      "--assignment",
    ];

    const valid = spawnSync(
      process.execPath,
      [...baseArguments, assignment.assignment_id, "--json"],
      { encoding: "utf8", windowsHide: true },
    );
    assert.equal(valid.status, 0, valid.stderr);
    assert.equal((JSON.parse(valid.stdout) as { valid: boolean }).valid, true);

    const wrongAssignment = spawnSync(
      process.execPath,
      [...baseArguments, "assignment-not-in-packet", "--json"],
      { encoding: "utf8", windowsHide: true },
    );
    assert.notEqual(wrongAssignment.status, 0);
    const rejected = JSON.parse(wrongAssignment.stdout) as {
      valid: boolean;
      issues: string[];
    };
    assert.equal(rejected.valid, false);
    assert.match(rejected.issues.join("\n"), /assignment/i);
  });

  it("does not steal an old-mtime lock from a still-live controller", async () => {
    const root = createProject({ context: false });
    const lockPath = join(root, ".codex-factory", "live-controller.lock");
    const readyPath = join(root, ".codex-factory", "live-controller.ready");
    const utilUrl = pathToFileURL(
      join(dirname(factoryCliPath()), "util.ts"),
    ).href;
    const holderCode = [
      "import { writeFileSync } from 'node:fs';",
      "import { withFileLock } from " + JSON.stringify(utilUrl) + ";",
      "withFileLock(" + JSON.stringify(lockPath) + ", () => {",
      "  writeFileSync(" + JSON.stringify(readyPath) + ", 'ready', 'utf8');",
      "  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 5000);",
      "});",
    ].join("\n");
    const holder = spawn(
      process.execPath,
      ["--import", "tsx", "--input-type=module", "--eval", holderCode],
      {
        cwd: join(dirname(factoryCliPath()), ".."),
        windowsHide: true,
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
    try {
      await waitForPath(readyPath);
      const old = new Date(Date.now() - 120_000);
      utimesSync(lockPath, old, old);
      let entered = false;
      assert.throws(
        () =>
          withFileLock(lockPath, () => {
            entered = true;
          }),
        /lock|owner|active|timed out/i,
      );
      assert.equal(entered, false);
    } finally {
      holder.kill();
    }
  });
});
