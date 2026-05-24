# Stage 111 Independent Rebuild Verification Certificate (2026-05-23)

## Verification objective

Independently re-run the promoted candidate on all registered external datasets and verify strict confirmatory gates directly from regenerated artifacts.

## Candidate and seeds used

- Candidate weights: `w_global=0.80`, `w_geno=0.25`, `w_marker=-0.05`
- Marker subsample seed: `4242`
- Bootstrap seeds: `9601` (all), `9602` (seen)

## Command used

`Rscript /Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/111_independent_rebuild_verify_promoted_candidate.R`

## Verification criteria

For each dataset:
1. stage-96 command returns status 0
2. `pass_confirmatory == TRUE`
3. both scope rows (`all`, `seen_genotypes`) exist
4. strict gate recheck from regenerated scope summary is TRUE:
   - gain >= 0 in both scopes
   - one-sided t <= 0.05 in both scopes
   - bootstrap P(gain>0) >= 0.95 in both scopes

## Outcome

- Datasets verified: 4/4
- `all_pass_confirmatory = TRUE`
- `all_strict_recheck = TRUE`

## Evidence files

- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/111_independent_verify/111_verify_detail.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/111_independent_verify/111_verify_summary.csv`

## Certificate verdict

The promoted candidate passes independent rebuild verification for strict external confirmatory status across all registered external datasets under the specified deterministic seed setting.
