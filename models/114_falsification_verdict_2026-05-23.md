# Stage 114 Falsification Verdict (2026-05-23)

## Protocol

Stage-114 evaluated promoted candidate (`0.80/0.25/-0.05`) under three modes per dataset:
- `none` (true data)
- `perm_train` (trait labels permuted in training split per outer fold)
- `perm_test` (trait labels permuted in test split per outer fold)

## Main falsification criterion

A strong anti-leakage signal is present if `perm_train` collapses confirmatory pass rates.

## Result summary

From:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/114_falsification/114_falsification_pass_rates.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/114_falsification/114_falsification_gain_summary.csv`

### True mode (`none`)
- pass rate = `1.0` for all 4 datasets.

### Training permutation (`perm_train`)
- pass rate = `0.0` for all 4 datasets.
- average gains become negative (`gain_all` and `gain_seen` both < 0 globally).

### Test permutation (`perm_test`)
- generally collapses, but `cimmyt_wheat` remained pass in this implementation.

## Interpretation

- The key falsification test (`perm_train`) **fully fails** across all datasets, which supports that the candidate depends on real train-side signal and is not a trivial artifact.
- `perm_test` is not a definitive null for *relative* RMSE ranking (both baseline and candidate are evaluated against the same shuffled labels), so its mixed behavior should be treated as secondary.

## Verdict

Falsification evidence is consistent with genuine predictive signal under the promoted method and inconsistent with a simple leakage-only explanation.
