export function formatDate(date: Date): string {
  return date.toISOString();
}

export function makeRunLabel(runId: string): string {
  return `Run: ${runId}`;
}
