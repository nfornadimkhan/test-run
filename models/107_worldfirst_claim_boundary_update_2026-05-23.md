# Stage 107 World-First Claim Boundary Update (2026-05-23)

## Why this update

Stage 106 established a single globally validated candidate with strict confirmatory external pass on all registered datasets. The remaining risk is over-claiming novelty. This document updates the claim boundary using explicit prior-art anchors.

## Prior-art anchors (external)

1. **Stacking itself is established prior art**
- Breiman (1996), *Stacked Regressions*, describes cross-validated level-1 combination of predictors and discusses non-negativity constraints.
- Source: [Berkeley PDF (Tech Report 367)](https://statistics.berkeley.edu/sites/default/files/tech-reports/367.pdf)

2. **Genomic stacking is established prior art**
- Frontiers (2021), *A Stacking Ensemble Learning Framework for Genomic Prediction* uses base learners plus OLS meta-learner for genomic prediction.
- Source: [Frontiers Genetics 2021](https://www.frontiersin.org/journals/genetics/articles/10.3389/fgene.2021.600040/full)

3. **Super Learner / convex NNLS combinations are established prior art**
- Super Learner literature and implementations commonly emphasize convex/non-negative combinations.
- Sources:
  - [Polley & van der Laan (2010) – Super Learner In Prediction](https://biostats.bepress.com/ucbbiostat/paper266/)
  - [sl3 NNLS meta-learner docs](https://tlverse.org/sl3/reference/Lrnr_nnls.html)

## What is NOT defensibly claimable

- "We proved universal method non-existence."
- "Unqualified priority claim over all stacking/ensemble/genomic-stacking methods."

These are contradicted by known prior-art families above.

## What IS defensibly claimable now

1. **Method-level claim (specific protocol + coefficients + gates):**
- A single global affine mixture candidate
  - `w_global=0.80`, `w_geno=0.25`, `w_marker=-0.05`
- was found and validated under the repository’s strict external confirmatory protocol (both scopes, t-test + bootstrap gates) across all four registered external datasets.

2. **Evidence-level claim:**
- This claim is reproducible from repository scripts and artifacts, including stage-96 outputs and tracker state.

3. **Novelty phrasing allowed (high confidence):**
- "No exact audited prior match for this full audited protocol/criterion bundle was found as of 2026-05-23."

## Claim-strength matrix

- **Absolute global-first existence claim:** NOT PROVEN
- **Project-level discovery claim:** PROVEN
- **Externally validated strict-pass candidate claim:** PROVEN
- **Exact audited match absent (bounded search statement):** SUPPORTED

## Approved final wording

"We discovered a project-level affine stacking candidate (`0.80/0.25/-0.05`) that reproducibly passes strict external confirmatory gates across all registered datasets in this repository. While stacking and genomic stacking are established prior-art families, no exact audited prior match to this full protocol-and-gate bundle was identified as of 2026-05-23."
