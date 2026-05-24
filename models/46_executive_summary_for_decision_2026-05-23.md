# Executive Summary for Decision (2026-05-23)

## Decision

- Deploy: `meta_alpha_blend`
- Do not replace with: `alpha_search_ranger_shift` (not robustly better)

## Plain-text prediction formula

`pred_hat(g,e) = alpha(e) * pred_baseline(g,e) + (1 - alpha(e)) * pred_gmean(g)`

## Key numbers

From fold-matched LOEO summaries:

- `meta_alpha_blend` RMSE:
  - all: `34.092708`
  - seen_genotypes: `34.419651`

- Best challenger (`alpha_search_ranger_shift`) RMSE:
  - all: `34.088529`
  - seen_genotypes: `34.419565`

Tiny numerical gains:
- all: `+0.004179`
- seen_genotypes: `+0.000085`

## Why challenger is not accepted

1. Paired uncertainty test: non-significant.
2. Bootstrap CI for gain includes zero.
3. Seed stability is weak:
   - probability challenger beats meta:
     - all: `0.18`
     - seen_genotypes: `0.14`

## Novelty boundary

- Supported: project-specific validated configuration in known stacking/MoE family.
- Not supported: “completely new in the world.”

## Single final statement

`meta_alpha_blend` is the current robust, evidence-backed choice for new-environment prediction in this repository.

