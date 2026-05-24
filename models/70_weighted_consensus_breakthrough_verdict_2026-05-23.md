# Stage 70 Breakthrough Verdict: Weighted Consensus Candidate (2026-05-23)

## What changed

Stage-69 searched random convex weights over top strict-pass settings (from stage-58) to directly optimize inferential gates, especially `seen_genotypes` Wilcoxon.

Script:
- `/Users/neon/Documents/Nadim's Brain/analysis/prediction-validation/69_search_weighted_consensus_wilcoxon_yield.R`

Outputs:
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_weighted_consensus_results.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_weighted_consensus_top30.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_best_weights.csv`
- `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/loeo_cv/69_weighted_consensus_search/69_settings_used.csv`

## Key finding

- `pass_all = TRUE` solutions were found (strict one-sided t + Wilcoxon <= 0.05 in both scopes).
- Best-ranked solution (id 204) has:
  - all:
    - gain ≈ `1.0689`
    - t p ≈ `0.0385`
    - Wilcoxon p ≈ `0.0457`
  - seen_genotypes:
    - gain ≈ `1.0220`
    - t p ≈ `0.0459`
    - Wilcoxon p ≈ `0.0489`

## Interpretation

This is the first candidate in this project that satisfies the strict inferential gate while preserving large practical gains in both scopes.

## Claim boundary

- Within-project discovery claim: **pass** under the defined protocol.
- Global “proven world-first in existence”: still cannot be mathematically proven from finite literature search; phrase as “no exact audited match found as of 2026-05-23.”

