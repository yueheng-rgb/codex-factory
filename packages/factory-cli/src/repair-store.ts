import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { factoryDirectory, loadConfig } from "./config.js";
import type { FactoryTask } from "./types.js";
import { assertWithinRoot, readJson, sha256, stableStringify } from "./util.js";

export class RunManagementError extends Error {
  constructor(public readonly code: string, message: string) {
    super(message);
    this.name = "RunManagementError";
  }
}

export function requireIdentifier(value: string): void {
  if (typeof value !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(value)) {
    throw new RunManagementError("INVALID_ID", "Invalid run id, task id, or request id");
  }
}

export function managedRunDirectory(root: string, runId: string): string {
  requireIdentifier(runId);
  return assertWithinRoot(root, join(factoryDirectory(root), "runs", runId));
}

export function repairJournalPath(root: string, runId: string): string {
  requireIdentifier(runId);
  return assertWithinRoot(root, join(factoryDirectory(root), "repairs", runId + ".json"));
}

export interface RepairLink {
  version: "1.0.0";
  project_id: string;
  root_run_id: string;
  root_task_id: string;
  parent_run_id: string;
  failed_task_id: string;
  new_run_id: string;
  request_id: string;
  request_hash: string;
  parent_receipt_hash: string;
  parent_receipt_path: string;
  task_contract_hash: string;
  repair_index: number;
  repair_limit: 2;
  created_at: string;
}

export interface RepairJournal {
  state: "PREPARING" | "COMMITTED";
  link: RepairLink;
  link_hash: string;
}

export function taskContractHash(tasks: FactoryTask[]): string {
  return sha256(stableStringify(tasks.map(({ status: _status, ...contract }) => contract)));
}

export function readRepairJournal(root: string, runId: string): RepairJournal {
  const record = readJson<RepairJournal>(repairJournalPath(root, runId));
  const link = record.link;
  if (!link || record.link_hash !== sha256(stableStringify(link)) ||
      link.version !== "1.0.0" || link.new_run_id !== runId ||
      link.project_id !== loadConfig(root).project_id ||
      !["PREPARING", "COMMITTED"].includes(record.state) ||
      link.repair_limit !== 2 || !Number.isInteger(link.repair_index) ||
      link.repair_index < 1 || link.repair_index > 2) {
    throw new RunManagementError("REPAIR_INTEGRITY", "Repair journal integrity verification failed");
  }
  for (const id of [link.root_run_id, link.root_task_id, link.parent_run_id, link.failed_task_id, link.request_id]) {
    requireIdentifier(id);
  }
  return record;
}

/** A reserved name keeps incomplete repairs unexecutable even before origin creation. */
export function assertRepairRunCommitted(root: string, runId: string, depth = 0): RepairLink | undefined {
  if (depth > 2) throw new RunManagementError("REPAIR_INTEGRITY", "Repair lineage is cyclic or exceeds the limit");
  const directory = managedRunDirectory(root, runId);
  const originPath = join(directory, "repair-origin.json");
  const journalPath = repairJournalPath(root, runId);
  if (!runId.startsWith("repair-r1-") && !existsSync(originPath) && !existsSync(journalPath)) return;
  if (!existsSync(journalPath) || !existsSync(originPath)) {
    throw new RunManagementError("REPAIR_INCOMPLETE", "Incomplete repair creation; preserve files and inspect the repair journal before manual recovery");
  }
  const record = readRepairJournal(root, runId);
  const origin = readJson<{ link_hash: string }>(assertWithinRoot(root, originPath));
  if (record.state !== "COMMITTED") {
    throw new RunManagementError("REPAIR_INCOMPLETE", "Repair is PREPARING, not committed; do not dispatch or delete its evidence");
  }
  if (origin.link_hash !== record.link_hash) {
    throw new RunManagementError("REPAIR_INTEGRITY", "Repair origin does not match the committed journal");
  }
  for (const name of ["run.json", "task-graph.json", "agent-registry.json", "spawn-plan.json"]) {
    if (!existsSync(assertWithinRoot(root, join(directory, name)))) {
      throw new RunManagementError("REPAIR_INCOMPLETE", "Committed repair is missing " + name);
    }
  }
  const graph = readJson<{ tasks: FactoryTask[] }>(join(directory, "task-graph.json"));
  if (!Array.isArray(graph.tasks) || taskContractHash(graph.tasks) !== record.link.task_contract_hash) {
    throw new RunManagementError("REPAIR_INTEGRITY", "Repair task contract changed after creation");
  }
  const link = record.link;
  const expectedParentPath = join(managedRunDirectory(root, link.parent_run_id), "verification", link.failed_task_id, "receipt.json");
  const receipt = readJson<Record<string, unknown>>(assertWithinRoot(root, expectedParentPath));
  const { receipt_hash: hash, ...unsigned } = receipt;
  if (hash !== link.parent_receipt_hash || hash !== sha256(stableStringify(unsigned)) ||
      receipt.verdict !== "FAIL" || receipt.run_id !== link.parent_run_id || receipt.task_id !== link.failed_task_id) {
    throw new RunManagementError("REPAIR_INTEGRITY", "Repair parent failure evidence no longer matches its origin");
  }
  const parent = assertRepairRunCommitted(root, link.parent_run_id, depth + 1);
  if (parent ? link.repair_index !== parent.repair_index + 1 || link.root_run_id !== parent.root_run_id || link.root_task_id !== parent.root_task_id
    : link.repair_index !== 1 || link.root_run_id !== link.parent_run_id || link.root_task_id !== link.failed_task_id) {
    throw new RunManagementError("REPAIR_INTEGRITY", "Repair lineage does not match its parent");
  }
  return record.link;
}

/** Content snapshot, not a lock: reject a concurrent update instead of returning mixed evidence. */
export function runFileSnapshot(root: string, directory: string): string {
  const files: Array<[string, string]> = [];
  const visit = (path: string): void => {
    assertWithinRoot(root, path);
    const stat = lstatSync(path);
    if (stat.isSymbolicLink()) throw new RunManagementError("RUN_INTEGRITY", "Run metadata must not contain symbolic links or junctions");
    if (stat.isDirectory()) {
      for (const name of readdirSync(path).sort()) {
        if (!name.endsWith(".lock")) visit(join(path, name));
      }
    } else if (stat.isFile()) {
      files.push([path, sha256(readFileSync(path))]);
    } else {
      throw new RunManagementError("RUN_INTEGRITY", "Unsupported run metadata file type");
    }
  };
  visit(directory);
  return sha256(stableStringify(files));
}
