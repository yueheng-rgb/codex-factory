import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { initializeConfig } from "../src/config.js";
import {
  executeSearch,
  GLM_ZHIPU_SEARCH_ENDPOINT,
  type FetchRequestInitLike,
  type SearchFetch,
  verifySearchEvidence,
} from "../src/search.js";

const FIXED_TIME = new Date("2026-07-18T12:00:00.000Z");
const TEST_KEY = "test-secret-key-that-must-never-be-persisted";

function createProject(searchEnabled = true): string {
  const root = mkdtempSync(join(tmpdir(), "codex-factory-search-"));
  initializeConfig(root, {
    searchProvider: searchEnabled ? "glm_zhipu" : "none",
  });
  return root;
}

function successFetch(
  inspect?: (input: string, init: FetchRequestInitLike) => void,
): SearchFetch {
  return async (input, init) => {
    inspect?.(input, init);
    const body = JSON.parse(init.body) as Record<string, unknown>;
    return {
      ok: true,
      status: 200,
      text: async () =>
        JSON.stringify({
          id: "provider-response-001",
          request_id: body.request_id,
          search_result: [
            {
              title: "Official result",
              link: "https://example.com/docs",
              snippet: "A verified snippet",
              content: "Provider content " + TEST_KEY,
            },
          ],
        }),
    };
  };
}

function executeOptions(fetchImpl: SearchFetch) {
  return {
    fetchImpl,
    now: () => new Date(FIXED_TIME),
    requestIdFactory: () => "client-request-001",
    secretResolver: () => TEST_KEY,
  };
}

test("rejects without calling the network when search is disabled", async (context) => {
  const root = createProject(false);
  context.after(() => rmSync(root, { recursive: true, force: true }));
  let calls = 0;

  const response = await executeSearch(root, "latest API documentation", {
    ...executeOptions(async () => {
      calls += 1;
      throw new Error("must not be called");
    }),
  });

  assert.equal(response.accepted, false);
  assert.equal(response.error_code, "SEARCH_DISABLED");
  assert.equal(calls, 0);
  assert.match(response.ledger_entry_hash ?? "", /^[a-f0-9]{64}$/);
});

test("rejects a missing key before making a network call", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));
  let calls = 0;

  const response = await executeSearch(root, "query", {
    fetchImpl: async () => {
      calls += 1;
      throw new Error("must not be called");
    },
    now: () => new Date(FIXED_TIME),
    secretResolver: () => undefined,
  });

  assert.equal(response.accepted, false);
  assert.equal(response.error_code, "MISSING_API_KEY");
  assert.equal(calls, 0);
});

test("executes the canonical live endpoint and persists redacted, verified evidence", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const response = await executeSearch(
    root,
    "latest API documentation",
    executeOptions(
      successFetch((input, init) => {
        assert.equal(input, GLM_ZHIPU_SEARCH_ENDPOINT);
        assert.equal(init.method, "POST");
        assert.equal(init.headers.Authorization, "Bearer " + TEST_KEY);
        const body = JSON.parse(init.body) as Record<string, unknown>;
        assert.equal(body.search_query, "latest API documentation");
        assert.equal(body.search_engine, "search_std");
        assert.equal(body.request_id, "client-request-001");
      }),
    ),
  );

  assert.equal(response.accepted, true);
  assert.equal(response.request_id, "client-request-001");
  assert.equal(response.response_id, "provider-response-001");
  assert.equal(response.result_count, 1);
  assert.equal(response.results[0]?.source_origin, "provider_search_result");
  assert.equal(response.results[0]?.content.includes(TEST_KEY), false);
  assert.equal(response.independent_verification?.verdict, "PASS");
  assert.match(response.query_hash, /^[a-f0-9]{64}$/);
  assert.match(response.raw_response_hash ?? "", /^[a-f0-9]{64}$/);
  assert.match(response.ledger_entry_hash ?? "", /^[a-f0-9]{64}$/);
  assert.ok(response.evidence_bundle_path);

  const evidenceFile = join(root, response.evidence_bundle_path!);
  const ledgerFile = join(root, ".codex-factory", "search", "invocations.jsonl");
  assert.equal(existsSync(evidenceFile), true);
  const persistedText = readFileSync(evidenceFile, "utf8") + readFileSync(ledgerFile, "utf8");
  assert.equal(persistedText.includes(TEST_KEY), false);
  assert.equal(persistedText.includes("Bearer "), false);
  assert.equal(persistedText.includes("latest API documentation"), false);
});

test("fails closed on HTTP errors without parsing a mock fallback", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const response = await executeSearch(
    root,
    "query",
    executeOptions(async () => ({
      ok: false,
      status: 429,
      text: async () => JSON.stringify({ search_result: [{ link: "https://mock.invalid" }] }),
    })),
  );

  assert.equal(response.accepted, false);
  assert.equal(response.error_code, "PROVIDER_HTTP_ERROR");
  assert.equal(response.mode, "live_api");
  assert.deepEqual(response.results, []);
});

test("fails closed when the provider returns no usable results", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const response = await executeSearch(
    root,
    "query",
    executeOptions(async (_input, init) => {
      const body = JSON.parse(init.body) as Record<string, unknown>;
      return {
        ok: true,
        status: 200,
        text: async () =>
          JSON.stringify({
            id: "provider-response-002",
            request_id: body.request_id,
            search_result: [],
          }),
      };
    }),
  );

  assert.equal(response.accepted, false);
  assert.equal(response.error_code, "NO_SEARCH_RESULTS");
  assert.equal(response.result_count, 0);
});

test("requires both provider request and response identifiers", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  for (const payload of [
    { id: "", request_id: "client-request-001" },
    { id: "provider-response-003", request_id: "" },
  ]) {
    const response = await executeSearch(
      root,
      "query",
      executeOptions(async () => ({
        ok: true,
        status: 200,
        text: async () =>
          JSON.stringify({
            ...payload,
            search_result: [{ title: "Result", link: "https://example.com" }],
          }),
      })),
    );
    assert.equal(response.accepted, false);
    assert.equal(response.error_code, "MISSING_PROVIDER_IDENTIFIERS");
  }
});

test("does not leak a key from a thrown provider error", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const response = await executeSearch(
    root,
    "query",
    executeOptions(async () => {
      throw new Error("Authorization: Bearer " + TEST_KEY);
    }),
  );

  assert.equal(response.accepted, false);
  assert.equal(response.error_code, "PROVIDER_REQUEST_FAILED");
  assert.equal(JSON.stringify(response).includes(TEST_KEY), false);
  const ledger = readFileSync(
    join(root, ".codex-factory", "search", "invocations.jsonl"),
    "utf8",
  );
  assert.equal(ledger.includes(TEST_KEY), false);
});

test("independent verifier rejects a tampered evidence bundle", async (context) => {
  const root = createProject();
  context.after(() => rmSync(root, { recursive: true, force: true }));

  const response = await executeSearch(root, "query", executeOptions(successFetch()));
  assert.equal(response.accepted, true);
  assert.ok(response.evidence_bundle);

  const tampered = structuredClone(response.evidence_bundle!);
  tampered.results[0]!.title = "Tampered";
  const verification = verifySearchEvidence(tampered, {
    now: () => new Date(FIXED_TIME),
  });
  assert.equal(verification.verdict, "FAIL");
  assert.equal(
    verification.checks.find((check) => check.check_id === "normalized_results_hash_matches")
      ?.passed,
    false,
  );
});
