export interface EffectAssumptions {
  baseline_success: number;
  addressable_failure_share: number;
  recovery_given_addressable: number;
  regression_given_baseline_success: number;
}

export function forecastEffect(input: EffectAssumptions) {
  const fields = ["baseline_success", "addressable_failure_share", "recovery_given_addressable",
    "regression_given_baseline_success"] as const;
  for (const field of fields) {
    const value = input?.[field];
    if (typeof value !== "number" || !Number.isFinite(value) || value < 0 || value > 1) {
      throw new Error(field + " must be a finite probability from 0 to 1");
    }
  }
  const b = input.baseline_success;
  const c = input.addressable_failure_share;
  const r = input.recovery_given_addressable;
  const h = input.regression_given_baseline_success;
  // Partition baseline successes and failures; do not add overlapping feature gains.
  const rescued = (1 - b) * c * r;
  const lost = b * h;
  const result = b + rescued - lost;
  return {
    kind: "CONDITIONAL_FORECAST" as const,
    baseline_success: b, forecast_success: result, rescued_probability: rescued, lost_probability: lost,
    delta_percentage_points: 100 * (rescued - lost),
    relative_success_change: b > 0 ? (result - b) / b : null,
    recovery_break_even: (1 - b) * c > 0 ? b * h / ((1 - b) * c) : null,
    cost_ratio_break_even: b > 0 ? result / b : null,
  };
}
