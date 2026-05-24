# Global Novelty Claim Protocol (Maximum Defensible Standard)

Date: 2026-05-23

## Hard limit

Claiming **“completely new, not existing in the world”** is not logically provable from finite evidence.

## Maximum defensible claim

Use this statement only:

`No directly matching method was found in the searched sources as of 2026-05-23.`

## Candidate method fingerprint template

A method is “directly matching” only if all core fingerprint fields match:

1. Prediction target:
   - unseen-environment genotype performance in LOEO design
2. Base predictors:
   - mixed-model baseline prediction
   - shrunk genotype historical mean
3. Gating / weighting:
   - environment-conditioned alpha in [0,1]
4. Meta-feature set:
   - environment covariates + predictor uncertainty/dispersion statistics
5. Calibration protocol:
   - leave-one-fold-out meta-training only
6. Objective:
   - fold-wise mean RMSE (all + seen-genotype scope)
7. Conservative variant:
   - alpha shrink toward baseline with nested fold tuning

If any one of these differs materially, classify as “related prior art,” not exact match.

## Reproducible search protocol

Search sources:
- Web of Science / Scopus / Crossref
- arXiv / bioRxiv
- PubMed
- GitHub repositories
- Google Patents / Lens

Query blocks:
- `"genotype environment" AND (stacking OR "mixture of experts" OR "meta learner")`
- `"leave one environment out" AND (blend OR gating OR ensemble)`
- `"plant breeding" AND "reaction norm" AND (stacking OR super learner)`
- `"distributionally robust" AND "genotype by environment" AND prediction`

Rules:
- Save exact queries and date.
- Keep top 200 hits/source.
- Deduplicate by DOI/title hash.
- Mark each as: exact match / partial overlap / irrelevant.
- Require two independent overlap checks before declaring “exact match.”

## Decision rule

- If at least one exact match exists -> not novel globally.
- If no exact match, but partial overlaps exist -> claim “new combination/instantiation.”
- If no exact match and no partial overlap in the audited corpus -> claim only:
  `No direct match found in audited corpus as of date.`

## Current status in this repository

- Related prior art exists (stacking, super learner, mixture-of-experts, GxE ensemble methods).
- Therefore global absolute novelty is **not claimable**.
- Project-level novelty (implementation + validation in this pipeline) is claimable.

