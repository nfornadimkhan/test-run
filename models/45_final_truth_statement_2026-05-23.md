# Final Truth Statement (2026-05-23)

## What was found (verified)

1. Best robust model in this repository right now:
   - `meta_alpha_blend`

2. Formula (plain text):
   - `pred_hat(g,e) = alpha(e) * pred_baseline(g,e) + (1 - alpha(e)) * pred_gmean(g)`

3. Empirical result:
   - It consistently stays among the top performers.
   - Competing variants can show tiny point-estimate gains, but these are not robust under uncertainty and seed-stability checks.

## What was not found

1. A defensible proof that this method class is completely new in the world.
2. A robustly superior replacement model that clearly and reproducibly beats `meta_alpha_blend` under current LOEO evidence.

## Strict non-hallucinated novelty statement

- This implementation is a validated project-specific configuration in a known method family (stacking / mixture-of-experts style blending).
- No exact matching formulation was found in the audited source set as of 2026-05-23, but global non-existence cannot be proven from finite search.

## Deployment-safe recommendation

- Use `meta_alpha_blend` as primary model for current new-environment prediction workflow.
- Keep ranger+shift alpha variants as sensitivity analyses, not as default replacement.

## Single-line decision

`meta_alpha_blend` is the current evidence-backed champion; no stronger, robust alternative has been verified yet.

