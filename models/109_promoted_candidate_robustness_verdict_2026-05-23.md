# Stage 109 Promoted Candidate Robustness Verdict (2026-05-23)

## Candidate under test

- `w_global = 0.80`
- `w_geno = 0.25`
- `w_marker = -0.05`

## Robustness protocol

Perturbation grid over evaluation randomness:
- marker subsampling seeds: `4201, 4242, 4301, 4444, 4601`
- bootstrap seed pairs: `(9601,9602), (9701,9702), (9801,9802)`
- total runs: `15`

Each run executes stage-96 across all 4 external datasets and evaluates strict confirmatory gate pass per dataset.

## Results

- `all4_pass_rate = 1.0` (15/15 runs)
- per-dataset pass rates:
  - `cimmyt_wheat = 1.0`
  - `dryad_rice = 1.0`
  - `dryad_wheat_sparse = 1.0`
  - `dryad_maize_met = 1.0`

## Evidence files

- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/109_seed_robustness/109_seed_robustness_detail.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/109_seed_robustness/109_seed_robustness_run_summary.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/109_seed_robustness/109_seed_robustness_dataset_passrate.csv`

## Verdict

The promoted candidate is not a single-seed artifact under the tested perturbation grid. Robustness evidence is now strong enough for a high-confidence external reproducibility claim within this repository’s protocol.
