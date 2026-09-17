export const COMMAND_OUTCOME_POLICY = "acceptance-recheck-v2" as const;
export type CommandOutcomePolicy = typeof COMMAND_OUTCOME_POLICY | "rg-files-v1";
export type CommandOutcome = "SUCCESS" | "NO_MATCH" | "RECHECK_PASSED" | "FAILURE";

interface ControllerAcceptanceCheck {
  method?: unknown;
  status?: unknown;
  exit_code?: unknown;
  stdout_sha256?: unknown;
  stderr_sha256?: unknown;
}

export function acceptanceCommand(method: string): string | undefined {
  const match = /^(?:command|cmd):([\s\S]*)$/.exec(method.trim());
  return match?.[1].trim() || undefined;
}

function passedRecheck(command: string, methods: string[], checks: ControllerAcceptanceCheck[]): boolean {
  if (checks.length !== methods.length || checks.some((check, index) => check.method !== methods[index])) return false;
  const matching = checks.filter((_, index) => acceptanceCommand(methods[index]) === command.trim());
  return matching.length > 0 && matching.every(check => check.status === "PASS" && check.exit_code === 0 &&
    [check.stdout_sha256, check.stderr_sha256].every(hash => typeof hash === "string" && /^[a-f0-9]{64}$/.test(hash)));
}

function standaloneFileListing(command: string): boolean {
  // Recognize only a small literal argv grammar, never interpret shell syntax.
  if (!/^rg(?:\.exe)?[ \t]+--files(?:[ \t]|$)/.test(command.trim())) return false;
  if (/[\r\n\x00-\x08\x0b-\x1f\x7f$`;|&<>(){}]/.test(command)) return false;
  const tokens: string[] = [];
  let rest = command.trim();
  while (rest) {
    const match = /^(?:'([^']*)'|"([^"\\]*)"|([^\s'"\\]+))(?=\s|$)/.exec(rest);
    if (!match) return false;
    tokens.push(match[1] ?? match[2] ?? match[3]);
    rest = rest.slice(match[0].length).trimStart();
  }
  if (!["rg", "rg.exe"].includes(tokens[0]) || tokens[1] !== "--files") return false;
  for (let index = 2; index < tokens.length; index++) {
    const token = tokens[index];
    if (["--hidden", "--no-ignore", "--no-ignore-vcs", "--no-config"].includes(token)) continue;
    if (token === "-g" || token === "--glob") {
      if (!tokens[++index] || tokens[index].startsWith("-")) return false;
    } else if (!token || token.startsWith("-")) return false;
  }
  return true;
}

export function reportedCommandOutcomes(
  commands: Array<{ command?: unknown; exit_code?: unknown }>,
  acceptanceMethods: string[],
  policy?: unknown,
  controllerChecks: ControllerAcceptanceCheck[] = [],
): CommandOutcome[] {
  if (policy !== undefined && policy !== "rg-files-v1" && policy !== COMMAND_OUTCOME_POLICY) throw new Error("Unsupported command outcome policy");
  return commands.map((report) => {
    if (report.exit_code === 0) return "SUCCESS";
    const command = report.command;
    if (policy === COMMAND_OUTCOME_POLICY && typeof command === "string" &&
        typeof report.exit_code === "number" && Number.isInteger(report.exit_code) && report.exit_code > 0 && report.exit_code < 126 &&
        passedRecheck(command, acceptanceMethods, controllerChecks)) return "RECHECK_PASSED";
    // Preserve v1 parsing exactly when reading historical receipts.
    const isAcceptance = typeof command === "string" && acceptanceMethods.some(method => policy === COMMAND_OUTCOME_POLICY
      ? acceptanceCommand(method) === command.trim()
      : method.startsWith("command:") && method.slice(8).trim() === command.trim());
    if (policy !== undefined && report.exit_code === 1 && typeof command === "string" && !isAcceptance &&
        standaloneFileListing(command)) return "NO_MATCH";
    return "FAILURE";
  });
}
