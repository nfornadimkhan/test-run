# Candidate Method for Strict Novelty Audit

Date: 2026-05-23

## Working name

Counterfactual Environment Stress Envelope Gating (CESEG)

## Method sketch (for audit, not novelty claim yet)

1. Build baseline predictor `b(g,e)` from current mixed model.
2. Build genotype historical predictor `h(g)` from training environments only.
3. For each test environment `e`, generate a **counterfactual stress envelope**:
   - perturb EC features along biologically plausible stress directions
   - evaluate sensitivity of `b(g,e)` under perturbations
4. Compute a robustness score `rho(e)` from envelope spread (e.g., worst-tail risk).
5. Gate prediction:
   - if `rho(e)` indicates instability, increase weight on `h(g)`
   - else keep weight on `b(g,e)`
6. Use nested LOEO calibration for all gating hyperparameters.

## Why this may be differentiable from prior local methods

- Current local methods gate on observed fold-level features.
- CESEG gates on **counterfactual perturbation response surfaces** of the predictor.

## Exact-match fingerprint for audit

A prior method is “exact match” only if it includes all:

1. Environment counterfactual perturbation envelope (not just observed covariates),
2. Envelope-derived gating for blending baseline + historical genotype predictor,
3. Nested LOEO calibration in MET setting,
4. Explicit unseen-environment target.

## Claim discipline

Until full audit is completed:

- Allowed: “candidate appears different from current local approaches.”
- Not allowed: “new to the world.”

