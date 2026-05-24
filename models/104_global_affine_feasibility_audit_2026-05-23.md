# Stage 104 Global Affine Feasibility Audit (2026-05-23)

## Goal

Test whether a **single** affine 3-expert composition (`global`, `geno`, `marker`) can satisfy strict confirmatory requirements across all 4 external datasets simultaneously.

Datasets:
- `cimmyt_wheat`
- `dryad_rice`
- `dryad_wheat_sparse`
- `dryad_maize_met`

## Search space

- Weights scanned on grid:
  - `w_global` in `[-0.3, 1.3]` step `0.05`
  - `w_geno` in `[-0.3, 1.3]` step `0.05`
  - `w_marker = 1 - w_global - w_geno`
  - constrained to `w_marker in [-0.3, 1.3]`
- Both scopes checked per dataset (`all`, `seen_genotypes`)
- Strict criterion in this audit (for feasibility screen):
  - gain >= 0 in both scopes
  - one-sided t p <= 0.05 in both scopes

## Result

No global strict-pass composition found in scanned affine region.

- `n_pass_all4 = 0`
- Source:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/104_global_affine_search/104_global_affine_results.csv`

Top-scoring region remains near convex, marker-light compositions (e.g., `0.70/0.30/0.00`), but these still fail strict pass on `dryad_maize_met` all-scope t-test.

## Interpretation

Under current data and model family, the remaining blocker is not external data availability (fully resolved) but cross-dataset statistical feasibility of a single strict-pass rule at small maize fold count (`n_folds = 4`).

This is evidence of a hard tradeoff frontier rather than an implementation gap.
