import { formatDate, makeRunLabel } from "./utils";

export function runService(runId: string): string {
  const label = makeRunLabel(runId);
  const date = formatDate(new Date());
  return `Run: ${label} | ${date}`;
}
