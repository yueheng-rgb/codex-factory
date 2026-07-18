import { existsSync, readFileSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { factoryDirectory, loadConfig, resolveSecret } from "./config.js";
import type {
  FactoryConfig,
  SearchEvidenceBundle,
  SearchEvidenceVerification,
  SearchResponse,
  SearchResultItem,
} from "./types.js";
import {
  appendJsonLine,
  ensureDirectory,
  newId,
  sha256,
  stableStringify,
  withFileLock,
  writeJsonAtomic,
} from "./util.js";

export const GLM_ZHIPU_SEARCH_ENDPOINT =
  "https://open.bigmodel.cn/api/paas/v4/web_search";

const SEARCH_ENGINE = "search_std";
const SEARCH_MODE = "live_api" as const;
const PROVIDER = "glm_zhipu" as const;
const LEDGER_GENESIS_HASH = "GENESIS";

export interface FetchResponseLike {
  ok: boolean;
  status: number;
  text(): Promise<string>;
}

export interface FetchRequestInitLike {
  method: "POST";
  headers: Record<string, string>;
  body: string;
  signal?: unknown;
}

export type SearchFetch = (
  input: string,
  init: FetchRequestInitLike,
) => Promise<FetchResponseLike>;

export interface ExecuteSearchOptions {
  fetchImpl?: SearchFetch;
  now?: () => Date;
  requestIdFactory?: () => string;
  secretResolver?: (projectRoot: string, name: string) => string | undefined;
  timeoutMs?: number;
}

interface SearchEvidenceArtifact {
  evidence_bundle: SearchEvidenceBundle;
  independent_verification: SearchEvidenceVerification;
}

interface SearchInvocationLedgerEntry {
  ledger_version: "1.0.0";
  invocation_id: string;
  provider: "glm_zhipu";
  mode: "live_api";
  endpoint: string;
  query_hash: string;
  request_id: string;
  response_id: string;
  retrieved_at: string;
  accepted: boolean;
  result_count: number;
  raw_response_hash?: string;
  evidence_bundle_path?: string;
  evidence_artifact_hash?: string;
  verifier_id?: string;
  verifier_verdict?: "PASS" | "FAIL";
  error_code?: string;
  previous_entry_hash: string;
  entry_hash: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function nonEmptyString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isSha256(value: string): boolean {
  return /^[a-f0-9]{64}$/.test(value);
}

function isWebUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

function redactSecret(value: string, secret: string): string {
  if (!value || !secret) return value;
  return value.split(secret).join("[REDACTED]");
}

function normalizeResults(payload: Record<string, unknown>, apiKey: string): SearchResultItem[] {
  const rawResults = Array.isArray(payload.search_result)
    ? payload.search_result
    : isRecord(payload.search_result)
      ? [payload.search_result]
      : [];

  const results: SearchResultItem[] = [];
  for (const rawResult of rawResults) {
    if (!isRecord(rawResult)) continue;
    const rawUrl = nonEmptyString(rawResult.link) || nonEmptyString(rawResult.url);
    const url = redactSecret(rawUrl, apiKey);
    if (!isWebUrl(url)) continue;

    const rawTitle = nonEmptyString(rawResult.title);
    results.push({
      title: redactSecret(rawTitle || "Untitled", apiKey),
      url,
      snippet: redactSecret(nonEmptyString(rawResult.snippet), apiKey),
      content: redactSecret(nonEmptyString(rawResult.content), apiKey),
      source_origin: "provider_search_result",
    });
  }
  return results;
}

function timestamp(options: ExecuteSearchOptions): string {
  const date = options.now ? options.now() : new Date();
  if (!(date instanceof Date) || Number.isNaN(date.valueOf())) {
    throw new Error("The injected clock returned an invalid Date");
  }
  return date.toISOString();
}

function makeBaseResponse(
  invocationId: string,
  requestId: string,
  queryHash: string,
  retrievedAt: string,
): SearchResponse {
  return {
    accepted: false,
    provider: PROVIDER,
    mode: SEARCH_MODE,
    invocation_id: invocationId,
    request_id: requestId,
    response_id: "",
    query_hash: queryHash,
    retrieved_at: retrievedAt,
    endpoint: GLM_ZHIPU_SEARCH_ENDPOINT,
    result_count: 0,
    results: [],
  };
}

function failed(
  base: SearchResponse,
  errorCode: string,
  errorMessage: string,
  changes: Partial<SearchResponse> = {},
): SearchResponse {
  return {
    ...base,
    ...changes,
    accepted: false,
    error_code: errorCode,
    error_message: errorMessage,
  };
}

function searchDirectory(projectRoot: string): string {
  return join(factoryDirectory(projectRoot), "search");
}

function ledgerPath(projectRoot: string): string {
  return join(searchDirectory(projectRoot), "invocations.jsonl");
}

function evidencePath(projectRoot: string, invocationId: string): string {
  return join(searchDirectory(projectRoot), "evidence", invocationId + ".json");
}

function verifiedLedgerHead(path: string): string {
  if (!existsSync(path)) return LEDGER_GENESIS_HASH;
  const lines = readFileSync(path, "utf8")
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0);
  let expectedPrevious = LEDGER_GENESIS_HASH;

  for (const line of lines) {
    const parsed = JSON.parse(line) as SearchInvocationLedgerEntry;
    if (parsed.previous_entry_hash !== expectedPrevious || !isSha256(parsed.entry_hash)) {
      throw new Error("Search invocation ledger chain is invalid");
    }
    const { entry_hash: recordedHash, ...unsigned } = parsed;
    if (sha256(stableStringify(unsigned)) !== recordedHash) {
      throw new Error("Search invocation ledger entry hash is invalid");
    }
    expectedPrevious = recordedHash;
  }
  return expectedPrevious;
}

function persistLedgerEntry(
  projectRoot: string,
  response: SearchResponse,
  artifact?: SearchEvidenceArtifact,
): { entry_hash: string; evidence_bundle_path?: string } {
  const absoluteRoot = resolve(projectRoot);
  const path = ledgerPath(absoluteRoot);
  const lockPath = path + ".lock";
  let bundleRelativePath: string | undefined;
  let artifactHash: string | undefined;

  if (artifact) {
    const absoluteEvidencePath = evidencePath(absoluteRoot, response.invocation_id);
    writeJsonAtomic(absoluteEvidencePath, artifact);
    bundleRelativePath = relative(absoluteRoot, absoluteEvidencePath).replace(/\\/g, "/");
    artifactHash = sha256(stableStringify(artifact));
  }

  return withFileLock(lockPath, () => {
    ensureDirectory(searchDirectory(absoluteRoot));
    const previousHash = verifiedLedgerHead(path);
    const unsigned = {
      ledger_version: "1.0.0" as const,
      invocation_id: response.invocation_id,
      provider: response.provider,
      mode: response.mode,
      endpoint: response.endpoint,
      query_hash: response.query_hash,
      request_id: response.request_id,
      response_id: response.response_id,
      retrieved_at: response.retrieved_at,
      accepted: response.accepted,
      result_count: response.result_count,
      raw_response_hash: response.raw_response_hash,
      evidence_bundle_path: bundleRelativePath,
      evidence_artifact_hash: artifactHash,
      verifier_id: response.independent_verification?.verifier_id,
      verifier_verdict: response.independent_verification?.verdict,
      error_code: response.error_code,
      previous_entry_hash: previousHash,
    };
    const entryHash = sha256(stableStringify(unsigned));
    appendJsonLine(path, { ...unsigned, entry_hash: entryHash });
    return { entry_hash: entryHash, evidence_bundle_path: bundleRelativePath };
  });
}

function finalizeFailure(projectRoot: string, response: SearchResponse): SearchResponse {
  try {
    const persisted = persistLedgerEntry(projectRoot, response);
    return { ...response, ledger_entry_hash: persisted.entry_hash };
  } catch {
    return {
      ...response,
      accepted: false,
      error_message: (response.error_message ?? "Search rejected.") +
        " The audit ledger could not be persisted.",
    };
  }
}

export function verifySearchEvidence(
  bundle: SearchEvidenceBundle,
  options: Pick<ExecuteSearchOptions, "now"> = {},
): SearchEvidenceVerification {
  const results = Array.isArray(bundle.results) ? bundle.results : [];
  const resultsHash = sha256(stableStringify(results));
  const checks = [
    {
      check_id: "canonical_provider_and_endpoint",
      passed:
        bundle.provider === PROVIDER &&
        bundle.mode === SEARCH_MODE &&
        bundle.endpoint === GLM_ZHIPU_SEARCH_ENDPOINT,
      detail: "Evidence must come from the configured GLM/Zhipu structured live endpoint.",
    },
    {
      check_id: "request_and_response_ids_present",
      passed: Boolean(nonEmptyString(bundle.request_id) && nonEmptyString(bundle.response_id)),
      detail: "Both provider request and response identifiers are required.",
    },
    {
      check_id: "content_hashes_well_formed",
      passed: isSha256(bundle.query_hash) && isSha256(bundle.raw_response_hash),
      detail: "The raw query and response are represented only by SHA-256 hashes.",
    },
    {
      check_id: "normalized_results_hash_matches",
      passed:
        isSha256(bundle.normalized_results_hash) &&
        bundle.normalized_results_hash === resultsHash,
      detail: "The normalized result list must match its recorded hash.",
    },
    {
      check_id: "non_empty_valid_results",
      passed:
        bundle.result_count > 0 &&
        bundle.result_count === results.length &&
        results.every(
          (result) =>
            isRecord(result) &&
            result.source_origin === "provider_search_result" &&
            isWebUrl(nonEmptyString(result.url)),
        ),
      detail: "At least one provider-originated HTTP(S) result is required.",
    },
  ];
  let checkedAt: Date;
  try {
    checkedAt = options.now ? options.now() : new Date();
    if (!(checkedAt instanceof Date) || Number.isNaN(checkedAt.valueOf())) {
      throw new Error("Invalid verifier clock");
    }
  } catch {
    checkedAt = new Date();
  }
  return {
    verifier_id: "factory_search_evidence_verifier",
    verifier_version: "1.0.0",
    independent_from_provider_acceptance: true,
    verdict: checks.every((check) => check.passed) ? "PASS" : "FAIL",
    checked_at: checkedAt.toISOString(),
    checks,
  };
}

function nativeFetch(): SearchFetch | undefined {
  const candidate = (globalThis as unknown as { fetch?: SearchFetch }).fetch;
  return typeof candidate === "function" ? candidate.bind(globalThis) : undefined;
}

function validateSearchConfig(config: FactoryConfig): string | undefined {
  const search = config.features.external_search;
  if (!search.enabled) return "SEARCH_DISABLED";
  if (search.provider !== PROVIDER) return "PROVIDER_NOT_ENABLED";
  if (search.require_explicit_user_opt_in !== true) return "EXPLICIT_OPT_IN_REQUIRED";
  if (search.endpoint !== GLM_ZHIPU_SEARCH_ENDPOINT) return "NON_CANONICAL_ENDPOINT";
  if (!search.api_key_env) return "API_KEY_ENV_NOT_CONFIGURED";
  return undefined;
}

export async function executeSearch(
  projectRoot: string,
  query: string,
  options: ExecuteSearchOptions = {},
): Promise<SearchResponse> {
  const normalizedQuery = query.trim();
  const invocationId = newId("search-invocation");
  let requestId = "";
  try {
    requestId = options.requestIdFactory
      ? nonEmptyString(options.requestIdFactory())
      : newId("search-request");
  } catch {
    requestId = "";
  }
  const queryHash = sha256(normalizedQuery);
  let retrievedAt: string;
  try {
    retrievedAt = timestamp(options);
  } catch {
    retrievedAt = new Date().toISOString();
  }
  const base = makeBaseResponse(invocationId, requestId, queryHash, retrievedAt);

  if (!requestId) {
    return finalizeFailure(
      projectRoot,
      failed(base, "INVALID_REQUEST_ID", "A non-empty provider request identifier is required."),
    );
  }

  if (!normalizedQuery) {
    return finalizeFailure(
      projectRoot,
      failed(base, "EMPTY_QUERY", "A non-empty search query is required."),
    );
  }

  let config: FactoryConfig;
  try {
    config = loadConfig(projectRoot);
  } catch {
    return finalizeFailure(
      projectRoot,
      failed(base, "CONFIG_ERROR", "A valid Codex Factory configuration is required."),
    );
  }

  const configError = validateSearchConfig(config);
  if (configError) {
    const messages: Record<string, string> = {
      SEARCH_DISABLED: "External search is not enabled for this project.",
      PROVIDER_NOT_ENABLED: "The GLM/Zhipu search provider is not enabled.",
      EXPLICIT_OPT_IN_REQUIRED: "External search requires explicit project opt-in.",
      NON_CANONICAL_ENDPOINT: "The configured search endpoint is not the canonical GLM/Zhipu endpoint.",
      API_KEY_ENV_NOT_CONFIGURED: "No API key environment variable is configured.",
    };
    return finalizeFailure(
      projectRoot,
      failed(base, configError, messages[configError] ?? "Search configuration was rejected."),
    );
  }

  const searchConfig = config.features.external_search;
  const secretResolver = options.secretResolver ?? resolveSecret;
  let apiKey: string | undefined;
  try {
    apiKey = secretResolver(projectRoot, searchConfig.api_key_env);
  } catch {
    return finalizeFailure(
      projectRoot,
      failed(base, "SECRET_RESOLUTION_FAILED", "The configured API key could not be resolved."),
    );
  }
  if (!apiKey?.trim()) {
    return finalizeFailure(
      projectRoot,
      failed(base, "MISSING_API_KEY", "The configured GLM/Zhipu API key is unavailable."),
    );
  }

  const fetchImpl = options.fetchImpl ?? nativeFetch();
  if (!fetchImpl) {
    return finalizeFailure(
      projectRoot,
      failed(base, "FETCH_UNAVAILABLE", "No live HTTP fetch implementation is available."),
    );
  }

  const timeoutMs = Math.max(1_000, Math.min(60_000, options.timeoutMs ?? 30_000));
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let response: FetchResponseLike;
  let rawResponse: string;
  try {
    response = await fetchImpl(GLM_ZHIPU_SEARCH_ENDPOINT, {
      method: "POST",
      headers: {
        Authorization: "Bearer " + apiKey,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        search_query: normalizedQuery,
        search_engine: SEARCH_ENGINE,
        search_intent: false,
        count: 5,
        search_recency_filter: "noLimit",
        request_id: requestId,
        user_id: "codex-factory",
      }),
      signal: controller.signal,
    });
    rawResponse = await response.text();
  } catch {
    return finalizeFailure(
      projectRoot,
      failed(base, "PROVIDER_REQUEST_FAILED", "The live search provider request failed."),
    );
  } finally {
    clearTimeout(timeout);
  }

  const rawResponseHash = sha256(rawResponse);
  if (!response.ok) {
    return finalizeFailure(
      projectRoot,
      failed(
        base,
        "PROVIDER_HTTP_ERROR",
        "The live search provider returned HTTP status " + response.status + ".",
        { raw_response_hash: rawResponseHash },
      ),
    );
  }

  let payload: Record<string, unknown>;
  try {
    const parsed = JSON.parse(rawResponse) as unknown;
    if (!isRecord(parsed)) throw new Error("Response is not an object");
    payload = parsed;
  } catch {
    return finalizeFailure(
      projectRoot,
      failed(base, "INVALID_PROVIDER_RESPONSE", "The provider response is not valid JSON data.", {
        raw_response_hash: rawResponseHash,
      }),
    );
  }

  const providerRequestId = nonEmptyString(payload.request_id);
  const responseId = nonEmptyString(payload.id) || nonEmptyString(payload.response_id);
  if (!providerRequestId || !responseId) {
    return finalizeFailure(
      projectRoot,
      failed(
        base,
        "MISSING_PROVIDER_IDENTIFIERS",
        "The provider response omitted its request or response identifier.",
        {
          request_id: providerRequestId || requestId,
          response_id: responseId,
          raw_response_hash: rawResponseHash,
        },
      ),
    );
  }
  if (providerRequestId !== requestId) {
    return finalizeFailure(
      projectRoot,
      failed(base, "REQUEST_ID_MISMATCH", "The provider request identifier did not match.", {
        request_id: providerRequestId,
        response_id: responseId,
        raw_response_hash: rawResponseHash,
      }),
    );
  }

  const results = normalizeResults(payload, apiKey);
  if (results.length === 0) {
    return finalizeFailure(
      projectRoot,
      failed(base, "NO_SEARCH_RESULTS", "The provider returned no usable search results.", {
        request_id: providerRequestId,
        response_id: responseId,
        raw_response_hash: rawResponseHash,
      }),
    );
  }

  const evidenceBundle: SearchEvidenceBundle = {
    bundle_version: "1.0.0",
    invocation_id: invocationId,
    provider: PROVIDER,
    mode: SEARCH_MODE,
    endpoint: GLM_ZHIPU_SEARCH_ENDPOINT,
    request_id: providerRequestId,
    response_id: responseId,
    query_hash: queryHash,
    raw_response_hash: rawResponseHash,
    normalized_results_hash: sha256(stableStringify(results)),
    retrieved_at: retrievedAt,
    result_count: results.length,
    results,
  };
  const independentVerification = verifySearchEvidence(evidenceBundle, {
    now: () => new Date(retrievedAt),
  });
  const candidate: SearchResponse = {
    ...base,
    accepted: independentVerification.verdict === "PASS",
    request_id: providerRequestId,
    response_id: responseId,
    result_count: results.length,
    results,
    raw_response_hash: rawResponseHash,
    evidence_bundle: evidenceBundle,
    independent_verification: independentVerification,
  };

  if (!candidate.accepted) {
    return finalizeFailure(
      projectRoot,
      failed(candidate, "EVIDENCE_VERIFICATION_FAILED", "Independent evidence verification failed."),
    );
  }

  const artifact: SearchEvidenceArtifact = {
    evidence_bundle: evidenceBundle,
    independent_verification: independentVerification,
  };
  try {
    const persisted = persistLedgerEntry(projectRoot, candidate, artifact);
    return {
      ...candidate,
      evidence_bundle_path: persisted.evidence_bundle_path,
      ledger_entry_hash: persisted.entry_hash,
    };
  } catch {
    return failed(
      candidate,
      "EVIDENCE_PERSIST_FAILED",
      "Search results were rejected because the evidence bundle or audit ledger could not be persisted.",
      {
        evidence_bundle_path: undefined,
        ledger_entry_hash: undefined,
      },
    );
  }
}
