# Stage 86 Manuscript Summary Draft (2026-05-23)

## Title (working)

Weighted Nonlinear Consensus for New-Environment Genomic Prediction: A Project-Level Discovery with Confirmatory Validation

## Problem

Predicting variety performance in new environments (G×E context) often shows unstable gains across folds and methods.  
The objective here was to discover a stronger method than baseline blend models and validate it under strict confirmatory rules.

## Method (project final candidate)

1. Build setting-level nonlinear corrections over baseline/meta components:
   - `delta = gmean_shrunk - baseline`
   - `psi = sign(delta) * sqrt(abs(delta))`
2. For each setting, predict fold-level coefficients out-of-fold and apply shrink/caps.
3. Build weighted convex consensus across top strict-pass settings:
   - `pred_final = sum_k w_k * pred_k`
4. Select weights via search under inferential and gain constraints.

## Internal validation protocol

- LOEO fold structure (22 folds) on repository dataset.
- Confirmatory gate:
  1. mean gain >= 0.8 RMSE in both scopes (`all`, `seen_genotypes`)
  2. one-sided paired t-test <= 0.05 in both scopes
  3. bootstrap `P(gain>0) >= 0.95` in both scopes

## Internal confirmatory result

From stage-74:
- `pass_confirmatory = TRUE`
- all:
  - mean gain `1.0502`
  - one-sided t `p=0.0396`
  - bootstrap `P(gain>0)=0.9699`
- seen_genotypes:
  - mean gain `1.0023`
  - one-sided t `p=0.0475`
  - bootstrap `P(gain>0)=0.9621`

## Novelty statement (bounded)

- No exact audited match to this final formulation was found in the audited source set as of 2026-05-23.
- Related families (stacking/MoE/nonlinear genomic prediction) do exist.

## Claim boundary

Allowed:
- project-level validated discovery with confirmatory pass.
- no exact audited prior match found as-of date.

Not allowed:
- absolute universal proof of global first-in-existence.

## External validation status

- External dataset registry, ingestion templates, and runbook are prepared:
  - stages 81–85.
- World-level evidence upgrade requires completion of multi-dataset independent external validation campaign.

