export const COMMAND_OUTCOME_POLICY = "rg-files-v1" as const;
export type CommandOutcome = "SUCCESS" | "NO_MATCH" | "FAILURE";

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
): CommandOutcome[] {
  if (policy !== undefined && policy !== COMMAND_OUTCOME_POLICY) throw new Error("Unsupported command outcome policy");
  return commands.map((report) => {
    if (report.exit_code === 0) return "SUCCESS";
    const command = report.command;
    if (policy === COMMAND_OUTCOME_POLICY && report.exit_code === 1 && typeof command === "string" &&
        !acceptanceMethods.some((method) => method.startsWith("command:") && method.slice(8).trim() === command.trim()) &&
        standaloneFileListing(command)) return "NO_MATCH";
    return "FAILURE";
  });
}
