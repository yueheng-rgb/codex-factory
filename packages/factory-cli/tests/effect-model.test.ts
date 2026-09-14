import assert from "node:assert/strict";
import { it } from "node:test";
import { forecastEffect } from "../evals/effect-model.js";

const base = { baseline_success: 0.7, addressable_failure_share: 0.4,
  recovery_given_addressable: 0.5, regression_given_baseline_success: 0.03 };
const near = (a: number, b: number) => assert.ok(Math.abs(a - b) < 1e-10, `${a} != ${b}`);

it("partitions successes/failures and reports net effects and break-even instead of summing feature claims", () => {
  const result = forecastEffect(base);
  near(result.forecast_success, 0.739);
  near(result.rescued_probability, 0.06);
  near(result.lost_probability, 0.021);
  near(result.delta_percentage_points, 3.9);
  near(result.recovery_break_even!, 0.175);
  near(result.cost_ratio_break_even!, 0.739 / 0.7);
  assert.ok(forecastEffect({ ...base, regression_given_baseline_success: 0.12 }).delta_percentage_points < 0);
  near(forecastEffect({ ...base, recovery_given_addressable: result.recovery_break_even! }).delta_percentage_points, 0);
});

it("handles zero/full baselines, no coverage and invalid probabilities without inventing relative gains", () => {
  const zero = forecastEffect({ ...base, baseline_success: 0 });
  near(zero.forecast_success, 0.2);
  assert.equal(zero.relative_success_change, null);
  assert.equal(zero.cost_ratio_break_even, null);
  const full = forecastEffect({ ...base, baseline_success: 1 });
  near(full.forecast_success, 0.97);
  assert.equal(full.recovery_break_even, null);
  near(forecastEffect({ ...base, addressable_failure_share: 0 }).forecast_success, 0.679);
  for (const b of [0, 1]) for (const c of [0, 1]) for (const r of [0, 1]) for (const h of [0, 1]) {
    const value = forecastEffect({ baseline_success: b, addressable_failure_share: c,
      recovery_given_addressable: r, regression_given_baseline_success: h }).forecast_success;
    assert.ok(value >= 0 && value <= 1);
  }
  for (const key of Object.keys(base)) for (const value of [-0.1, 1.1, NaN, Infinity, "0.5", undefined]) {
    assert.throws(() => forecastEffect({ ...base, [key]: value }), /finite probability/);
  }
});
