# Reproducible Novelty Search Protocol (2026-05-23)

## Objective

Audit whether the exact formulation used in this repo appears in prior GxE prediction literature:

`pred_hat(g,e) = alpha(e)*pred_baseline(g,e) + (1-alpha(e))*pred_gmean(g)`

This protocol is designed to avoid hallucinated novelty claims.

## Search date and context

- Date executed: 2026-05-23
- Environment: Codex web search tool
- Topic scope: plant/crop genomic prediction, MET, GxE, LOEO/CV0, stacking, mixture-of-experts

## Query sets executed

Set A (broad prior-art family):
1. "meta-learner stacking genotype by environment prediction leave-one-environment-out"
2. "BMORS Bayesian multi-output regressor stacking GxE"
3. "learnMET CV0 leave-one-environment-out genomic prediction"
4. "mixture of experts genotype environment prediction"

Set B (direct overlap orientation):
1. "leave-one-environment-out stacking genomic prediction"
2. "genotype by environment mixture of experts prediction"
3. "environment-specific weights ensemble genomic prediction"
4. "learnMET stacked ensemble CV0"

Set C (formula-focused):
1. "\"alpha(e)\" \"genomic prediction\" \"environment\" \"1-alpha\""
2. "\"convex combination\" \"baseline\" \"genotype mean\" prediction"
3. "\"leave-one-environment-out\" \"mixture of experts\" \"crop\""
4. "\"stacking\" \"environment-specific weights\" \"plant breeding\""

Set D (domain-focused pass):
1. "leave-one-environment-out stacking_reg" with domains `cjubin.github.io`, `rdrr.io`
2. "Bayesian multi-output regressor stacking genotype × environment" with domain `pmc.ncbi.nlm.nih.gov`
3. "mixture of experts genomic prediction crop breeding" with domain `pmc.ncbi.nlm.nih.gov`
4. "ensemble genotype-by-environment leave-one-environment-out" with domain `pmc.ncbi.nlm.nih.gov`

## Inclusion criteria

A hit is included as evidence if:
1. It is a primary source (paper or official package docs/source).
2. It is directly about genomic prediction / breeding / GxE / MET / LOEO (or foundational stacking/MoE theory).
3. It contains explicit modeling structure relevant to predictor-combination or environment-conditioned weighting.

## Exclusion criteria

A hit is excluded if:
1. Domain/topic is unrelated to genomic prediction in breeding (medical guidance, unrelated genomics, etc.).
2. Page is aggregator/noise without model details.
3. Duplicative hit with no additional information.

## Key included sources from this audit

- BMORS (two-stage stacking in plant breeding):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC6778812/
- learnMET CV0/LOEO stacked model docs:
  - https://cjubin.github.io/learnMET/articles/vignette_cv_stacking_indica.html
  - https://rdrr.io/github/cjubin/learnMET/src/R/predict_trait_MET_cv.R
- MoEGP (gating-weighted expert combination in crop GP):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/
- EXGEP (ensemble in GxE with LOEO evaluation):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12354955/
- Foundational methods:
  - Stacking / Super Learner: https://doi.org/10.2202/1544-6115.1309
  - Mixture of Experts: https://doi.org/10.1162/neco.1991.3.1.79

## Decision rules used for novelty statement

1. If exact formula-level match is found in included sources:
   - Claim: "direct prior formulation exists."
2. If only structural/family overlap is found:
   - Claim: "belongs to known family; exact match not found in audited set."
3. Never claim global non-existence from finite search.

## Result under this protocol

- Exact formula-level match for the specific two-term blend with environment-specific alpha and complementary weight to genotype-history predictor:
  - **Not found in this audited source set**.
- Structural/family overlap:
  - **Found** (stacking/meta-learning and MoE gating families).

## Allowed reporting sentence

"As of 2026-05-23, under the audited search protocol above, we did not find an exact prior publication with the same explicit two-term environment-weighted blend used here; however, the method is clearly within established stacking/mixture-of-experts families."

