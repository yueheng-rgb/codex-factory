import { appendTrustedContextEvent } from "./context-space.js";
import {
  queryKnowledge,
  verifyKnowledgeStore,
  type KnowledgeEntry,
} from "./knowledge.js";
import type { AgentProfile, ContextEvent, FactoryTask } from "./types.js";

const MAX_QUERY_CHARACTERS = 1_000;
const MAX_KNOWLEDGE_ENTRIES = 6;
const MAX_EXCERPT_CHARACTERS = 1_200;
const MAX_TOTAL_EXCERPT_CHARACTERS = 6_000;

const QUERY_STOP_WORDS = new Set([
  "a",
  "an",
  "and",
  "are",
  "as",
  "at",
  "be",
  "by",
  "for",
  "from",
  "in",
  "is",
  "it",
  "of",
  "on",
  "or",
  "that",
  "the",
  "this",
  "to",
  "with",
  "task",
  "execute",
  "implement",
]);

export interface AssignmentKnowledgeExcerpt {
  entry_id: string;
  title: string;
  excerpt: string;
  source_uri: string;
  source_sha256: string;
  source_kind: string;
  tags: string[];
  status: "active";
  source_binding: "project_file";
  entry_digest: string;
  content_digest: string;
}

function boundedTaskQuery(task: FactoryTask): string {
  return [
    task.title,
    task.description,
    ...task.acceptance_methods,
    ...task.required_artifacts,
  ]
    .join(" ")
    .normalize("NFKC")
    .replace(/\s+/gu, " ")
    .trim()
    .slice(0, MAX_QUERY_CHARACTERS);
}

function queryTerms(query: string): string[] {
  const raw = query.match(/[\p{Letter}\p{Number}_:/.-]+/gu) ?? [];
  const seen = new Set<string>();
  const terms: string[] = [];
  for (const value of raw) {
    const term = value.normalize("NFKC").toLocaleLowerCase().trim();
    if (term.length < 2 || QUERY_STOP_WORDS.has(term) || seen.has(term)) continue;
    seen.add(term);
    terms.push(term);
  }
  return terms.slice(0, 32);
}

function relevantExcerpt(content: string, terms: string[], limit: number): string {
  if (content.length <= limit) return content;
  const normalized = content.toLocaleLowerCase();
  let matchIndex = -1;
  for (const term of terms) {
    const index = normalized.indexOf(term);
    if (index >= 0 && (matchIndex < 0 || index < matchIndex)) matchIndex = index;
  }
  const center = matchIndex >= 0 ? matchIndex : 0;
  const start = Math.max(0, Math.min(content.length - limit, center - Math.floor(limit / 4)));
  const end = Math.min(content.length, start + limit);
  return (start > 0 ? "…" : "") + content.slice(start, end) + (end < content.length ? "…" : "");
}

function boundedExcerpts(entries: KnowledgeEntry[], query: string): AssignmentKnowledgeExcerpt[] {
  const terms = queryTerms(query);
  const selected: AssignmentKnowledgeExcerpt[] = [];
  let remaining = MAX_TOTAL_EXCERPT_CHARACTERS;
  for (const entry of entries.slice(0, MAX_KNOWLEDGE_ENTRIES)) {
    if (remaining <= 0) break;
    if (entry.status !== "active" || entry.source_binding !== "project_file") {
      throw new Error(
        "Automatic assignment memory received knowledge that is not active and source-bound",
      );
    }
    const excerptLimit = Math.min(MAX_EXCERPT_CHARACTERS, remaining);
    const excerpt = relevantExcerpt(entry.content, terms, excerptLimit);
    remaining -= excerpt.length;
    selected.push({
      entry_id: entry.entry_id,
      title: entry.title,
      excerpt,
      source_uri: entry.source_uri,
      source_sha256: entry.source_sha256,
      source_kind: entry.source_kind,
      tags: entry.tags,
      status: entry.status,
      source_binding: entry.source_binding,
      entry_digest: entry.content_hash,
      content_digest: entry.content_digest,
    });
  }
  return selected;
}

function visibleRoles(profile: AgentProfile): string[] {
  return [
    ...new Set([
      profile.role,
      "main_controller",
      "librarian",
      "verifier",
      "drift_auditor",
    ]),
  ];
}

/**
 * Retrieve source-bound, active knowledge for one assignment and bind the bounded
 * excerpts to the Context ledger. The knowledge module verifies the store before
 * returning any result, so source drift and store tampering fail closed here.
 */
export function appendAssignmentKnowledgeContext(
  projectRoot: string,
  runId: string,
  assignmentId: string,
  task: FactoryTask,
  profile: AgentProfile,
): ContextEvent | undefined {
  const query = boundedTaskQuery(task);
  if (!query) return undefined;
  const matches = queryKnowledge(projectRoot, query, {
    requestingRole: profile.role,
    limit: MAX_KNOWLEDGE_ENTRIES,
    sourceBoundOnly: true,
  });
  if (matches.length === 0) return undefined;

  const verification = verifyKnowledgeStore(projectRoot);
  if (!verification.valid || !verification.store_root_hash) {
    throw new Error(
      "Knowledge store failed verification before assignment injection: " +
        verification.issues.join("; "),
    );
  }
  const entries = boundedExcerpts(matches, query);
  if (entries.length === 0) return undefined;

  return appendTrustedContextEvent(
    projectRoot,
    "knowledge_retrieval",
    "main_controller",
    {
      schema_version: "1.0.0",
      run_id: runId,
      assignment_id: assignmentId,
      task_id: task.task_id,
      target_role: profile.role,
      query,
      selection_policy:
        "active_current_source_role_visible_ranked_bounded_excerpt_v1",
      entries,
      total_excerpt_characters: entries.reduce(
        (total, entry) => total + entry.excerpt.length,
        0,
      ),
      visible_to_roles: visibleRoles(profile),
    },
    {
      basis: "trusted_internal",
      authority: "factory_control_plane",
      source: {
        kind: "knowledge_store_verified",
        reference: ".codex-factory/context/state.db#knowledge-store",
        store_digest: verification.store_root_hash,
        entry_digests: entries.map((entry) => entry.entry_digest),
        source_digests: entries.map((entry) => entry.source_sha256),
        content_digests: entries.map((entry) => entry.content_digest),
      },
    },
  );
}
