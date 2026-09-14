import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { forecastEffect, type EffectAssumptions } from "../evals/effect-model.js";
import { ensureDirectory, parseJsonFileText, sha256, writeJsonAtomic } from "../src/util.js";

if (process.argv.length > 3) throw new Error("Usage: npm run eval:forecast [-- <assumptions.json>]");
const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const path = resolve(process.argv[2] ?? join(packageRoot, "evals/effect-assumptions.json"));
const bytes = readFileSync(path);
const input = parseJsonFileText<{
  kind: string; basis: string; comparison: string; scenarios: Array<EffectAssumptions & { id: string }>;
}>(bytes.toString("utf8"));
if (input?.kind !== "ILLUSTRATIVE_ASSUMPTIONS_NOT_MEASURED" || typeof input.basis !== "string" || !input.basis.trim() ||
    typeof input.comparison !== "string" || !input.comparison.trim() || !Array.isArray(input.scenarios) ||
    input.scenarios.length < 1 || input.scenarios.length > 20) throw new Error("Require labelled assumptions, comparison and 1-20 scenarios");
const ids = new Set<string>();
const scenarios = input.scenarios.map((scenario) => {
  if (!scenario || typeof scenario.id !== "string" || !/^[a-z0-9-]{1,60}$/.test(scenario.id) || ids.has(scenario.id)) {
    throw new Error("Scenario IDs must be distinct lowercase names");
  }
  ids.add(scenario.id);
  return { id: scenario.id, assumptions: scenario, result: forecastEffect(scenario) };
});
// Vary one input at a time, retaining each scenario's other explicit assumptions.
const sensitivity = scenarios.map((scenario) => ({ id: scenario.id, rows: [0.5, 0.7, 0.9].map((b) =>
  forecastEffect({ ...scenario.assumptions, baseline_success: b })) }));
const report = { kind: "CONDITIONAL_FORECAST_NOT_EMPIRICAL", generated_at: new Date().toISOString(),
  actual_agent_trials: 0, measured_success_rate: null, statistical_confidence_interval: null,
  assumptions_path: path, assumptions_sha256: sha256(bytes), basis: input.basis, comparison: input.comparison,
  formula: "p_factory = b + (1-b)*c*r - b*h", scenarios, sensitivity,
  limitations: ["All probabilities are uncalibrated assumptions; architecture alone does not identify their values.",
    "Scenario spread is not a confidence interval or the expected range for this project. No scenario is a best estimate.",
    "c covers the union of addressable baseline failures; never sum clarification, teaching and probe percentages.",
    "A finite recovery_break_even above 1 means no feasible recovery can offset assumed losses. A null threshold means the recovery term has zero mass.",
    "For the same task mix and chosen cost unit, cost per success improves only if mean cost ratio is below cost_ratio_break_even. Cost is not measured here.",
    "Zero baseline success makes relative gain and cost-per-success comparison undefined; absolute changes remain available."] };
const outputRoot = join(packageRoot, "outputs");
ensureDirectory(outputRoot);
const directory = mkdtempSync(join(outputRoot, "effect-forecast-"));
const percent = (n: number) => (100 * n).toFixed(2) + "%";
const table = ["| Scenario | b | c | r | h | Forecast success | Change (pp) | Cost ratio break-even |",
  "| --- | --- | --- | --- | --- | --- | --- | --- |",
  ...scenarios.map(({ id, assumptions: a, result: r }) => "| " + [id, percent(a.baseline_success),
    percent(a.addressable_failure_share), percent(a.recovery_given_addressable), percent(a.regression_given_baseline_success),
    percent(r.forecast_success), r.delta_percentage_points.toFixed(2), r.cost_ratio_break_even?.toFixed(4) ?? "undefined"].join(" | ") + " |")];
writeJsonAtomic(join(directory, "forecast.json"), report);
writeFileSync(join(directory, "assumptions.json"), bytes);
writeFileSync(join(directory, "README.md"), ["# Conditional Effect Forecast", "",
  "ILLUSTRATIVE INPUTS. NOT MEASURED SUCCESS RATES. NOT A CALIBRATED PROJECT PREDICTION.", "", input.basis,
  "", "Comparison: " + input.comparison, "", "`" + report.formula + "`", "",
  "b = baseline success; c = addressable share of baseline failures; r = recovery within that share; h = losses among baseline successes.",
  "", ...table, "", "## Baseline Sensitivity", "",
  "Same c/r/h within each row; b changes to 50%, 70%, 90%. Values are percentage-point changes.", "",
  ...sensitivity.map((item) => "- " + item.id + ": " + item.rows.map((r) => r.delta_percentage_points.toFixed(2)).join(" / ")),
  "", "## Limits", "", ...report.limitations.map((line) => "- " + line), "",
  "[Exact inputs](assumptions.json) | [Machine-readable calculation](forecast.json)", ""].join("\n"), "utf8");
process.stdout.write("CONDITIONAL FORECAST ONLY; all numeric inputs are assumptions.\n" + table.join("\n") +
  "\nReport: " + join(directory, "README.md") + "\n");
