import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { afterEach, describe, it } from "node:test";
import { initializeConfig } from "../src/config.js";
import {
  appendContextEvent,
  appendTrustedContextEvent,
  contextDatabasePath,
  createContextPacket,
  initializeContextSpace,
  queryContextEvents,
  readContextEvents,
  verifyContextLedger,
  verifyContextPacket,
} from "../src/context-space.js";
import type { ContextPacket } from "../src/types.js";
import { sha256, stableStringify } from "../src/util.js";

const roots: string[] = [];

function createProject(): string {
  const root = mkdtempSync(join(tmpdir(), "codex-context-admission-"));
  roots.push(root);
  initializeConfig(root, { externalContext: true });
  initializeContextSpace(root);
  return root;
}

function rehashPacket(packet: ContextPacket): ContextPacket {
  const { packet_hash: _oldHash, ...unsigned } = packet;
  return { ...packet, packet_hash: sha256(stableStringify(unsigned)) };
}

function receiptSource(value: string) {
  return {
    kind: "control_plane_receipt" as const,
    reference: ".codex-factory/receipts/" + value + ".json",
    sha256: sha256(value),
  };
}

afterEach(() => {
  for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
});

describe("Context Space admission", () => {
  it("does not trust a public append even when its actor spoofs the main controller", () => {
    const root = createProject();
    const spoofed = appendContextEvent(root, "requirement", "main_controller", {
      requirement: "spoofed public input",
      visible_to_roles: ["verifier"],
    });
    assert.equal(spoofed.admission.status, "candidate");
    assert.equal(spoofed.admission.basis, "untrusted_append");

    const { packet } = createContextPacket(root, "run-spoof", "verifier");
    assert.equal(packet.trusted_context.some((item) => item.event_id === spoofed.event_id), false);
    assert.equal(
      packet.untrusted_context_candidates.some((item) => item.event_id === spoofed.event_id),
      true,
    );

    const forged = structuredClone(packet);
    const [candidate] = forged.untrusted_context_candidates.splice(0, 1);
    assert.ok(candidate);
    forged.trusted_context.push(candidate);
    const result = verifyContextPacket(root, rehashPacket(forged));
    assert.equal(result.valid, false);
    assert.match(result.issues.join("\n"), /non-admitted|candidate|trusted/i);
  });

  it("requires an explicit source-bound trusted path and rejects a spoofed internal actor", () => {
    const root = createProject();
    assert.throws(
      () =>
        appendTrustedContextEvent(
          root,
          "decision",
          "temporary_agent",
          { decision: "pretend controller", visible_to_roles: ["verifier"] },
          {
            basis: "trusted_internal",
            authority: "factory_control_plane",
            source: receiptSource("spoof"),
          },
        ),
      /actor|control-plane identity/i,
    );

    const admitted = appendTrustedContextEvent(
      root,
      "decision",
      "main_controller",
      { decision: "source-bound controller decision", visible_to_roles: ["verifier"] },
      {
        basis: "trusted_internal",
        authority: "factory_control_plane",
        source: receiptSource("controller-decision"),
      },
    );
    assert.equal(admitted.admission.status, "admitted");
    const { packet } = createContextPacket(root, "run-trusted", "verifier");
    assert.equal(packet.trusted_context.some((item) => item.event_id === admitted.event_id), true);
    assert.equal(verifyContextPacket(root, packet).valid, true);
  });

  it("filters raw reads and FTS queries by the requested role", () => {
    const root = createProject();
    const privateEvent = appendContextEvent(root, "decision", "main_controller", {
      decision: "rolequeryneedle librarian only",
      visible_to_roles: ["librarian"],
    });
    const publicEvent = appendContextEvent(root, "requirement", "main_controller", {
      requirement: "rolequeryneedle public",
    });

    const verifierResults = queryContextEvents(root, "rolequeryneedle", {
      targetRole: "verifier",
    });
    assert.deepEqual(verifierResults.map((event) => event.event_id), [publicEvent.event_id]);
    const librarianResults = queryContextEvents(root, "rolequeryneedle", {
      targetRole: "librarian",
    });
    assert.deepEqual(
      new Set(librarianResults.map((event) => event.event_id)),
      new Set([privateEvent.event_id, publicEvent.event_id]),
    );
    assert.deepEqual(
      readContextEvents(root, "verifier").map((event) => event.event_id),
      [publicEvent.event_id],
    );
    assert.throws(
      () => queryContextEvents(root, "rolequeryneedle", { targetRole: "" }),
      /role is required/i,
    );
  });

  it("rejects likely secrets without echoing them", () => {
    const root = createProject();
    const secret = "sk-this-is-a-secret-value-123456789";
    let message = "";
    try {
      appendContextEvent(root, "requirement", "user", { nested: { api_key: secret } });
    } catch (error) {
      message = (error as Error).message;
    }
    assert.match(message, /secret material/i);
    assert.equal(message.includes(secret), false);
    assert.equal(verifyContextLedger(root).event_count, 0);
  });

  it("migrates 1.1 events to separately anchored legacy candidates", () => {
    const root = createProject();
    const legacy = appendContextEvent(root, "requirement", "main_controller", {
      requirement: "pre-admission ledger entry",
    });
    const database = new DatabaseSync(contextDatabasePath(root));
    try {
      database.prepare("DELETE FROM context_event_admissions").run();
      database
        .prepare("DELETE FROM metadata WHERE key IN ('expected_admission_count', 'expected_admission_root_hash')")
        .run();
      database.prepare("UPDATE metadata SET value = '1.1.0' WHERE key = 'schema_version'").run();
      database
        .prepare("UPDATE metadata SET value = ? WHERE key = 'authority'")
        .run("sqlite_hash_chain_and_verified_artifacts");
    } finally {
      database.close();
    }

    initializeContextSpace(root);
    const [migrated] = readContextEvents(root, "verifier");
    assert.equal(migrated.event_id, legacy.event_id);
    assert.equal(migrated.admission.status, "candidate");
    assert.equal(migrated.admission.basis, "legacy_unverified");
    const verification = verifyContextLedger(root);
    assert.equal(verification.valid, true, verification.issues.join("; "));
    assert.equal(verification.admitted_event_count, 0);
    assert.equal(verification.candidate_event_count, 1);
  });

  it("detects tampering with a separately anchored admission receipt", () => {
    const root = createProject();
    const event = appendTrustedContextEvent(
      root,
      "risk",
      "main_controller",
      { risk: "source-bound risk", visible_to_roles: ["verifier"] },
      {
        basis: "trusted_internal",
        authority: "factory_control_plane",
        source: receiptSource("risk"),
      },
    );
    const database = new DatabaseSync(contextDatabasePath(root));
    try {
      database
        .prepare("UPDATE context_event_admissions SET source_json = ? WHERE event_id = ?")
        .run(stableStringify(receiptSource("forged-risk")), event.event_id);
    } finally {
      database.close();
    }
    const verification = verifyContextLedger(root);
    assert.equal(verification.valid, false);
    assert.match(verification.issues.join("\n"), /admission|receipt|hash/i);
    assert.throws(
      () => appendContextEvent(root, "risk", "user", { risk: "must fail closed" }),
      /invalid|integrity|admission|hash/i,
    );
  });

  it("does not include knowledge retrieval globally and requires explicit packet selection", () => {
    const root = createProject();
    const digest = sha256("knowledge");
    const knowledge = appendTrustedContextEvent(
      root,
      "knowledge_retrieval",
      "main_controller",
      {
        run_id: "run-explicit",
        assignment_id: "assignment-knowledge",
        target_role: "implementation",
        visible_to_roles: ["implementation"],
        entries: [{ entry_id: "entry-1", content_digest: digest }],
      },
      {
        basis: "trusted_internal",
        authority: "factory_control_plane",
        source: {
          kind: "knowledge_store_verified",
          reference: ".codex-factory/knowledge/state.db",
          store_digest: digest,
          entry_digests: [digest],
          source_digests: [digest],
          content_digests: [digest],
        },
      },
    );

    const defaultPacket = createContextPacket(root, "run-default", "implementation").packet;
    assert.equal(defaultPacket.source_event_ids.includes(knowledge.event_id), false);
    const explicitPacket = createContextPacket(root, "run-explicit", "implementation", {
      sourceEventIds: [knowledge.event_id],
    }).packet;
    assert.equal(explicitPacket.trusted_context[0]?.event_id, knowledge.event_id);
    assert.equal(
      verifyContextPacket(root, explicitPacket, {
        runId: "run-explicit",
        targetRole: "implementation",
        assignmentId: "assignment-knowledge",
      }).valid,
      true,
    );
  });
});
