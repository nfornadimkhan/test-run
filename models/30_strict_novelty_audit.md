# Strict Novelty Audit (Global) — 2026-05-23

## Question

Can we claim the current method is “completely new, not existing in this world”?

## Short answer

No. That claim is not supportable.

## Why

The current best method in this project (`meta_alpha_blend`) is an environment-conditioned blending/stacking of predictors. That family already exists in the literature:

- **Stacked generalization** (Wolpert, 1992)
  - https://yanpuli.github.io/files/stacking/Wolpert1992.pdf
- **Super Learner / stacking framework** (van der Laan et al., 2007)
  - https://www.ovid.com/journals/sgmbio/abstract/10.2202/1544-6115.1309~super-learner
- **Adaptive mixtures of experts** (Jacobs et al., 1991)
  - https://direct.mit.edu/neco/article/3/1/79/5560/Adaptive-Mixtures-of-Local-Experts

Additionally, plant-breeding-specific papers/tools already use stacking in multi-trait/multi-environment settings:

- BMORS (Bayesian multi-output regressor stacking for plant breeding data)
  - https://pubmed.ncbi.nlm.nih.gov/31427455/

Recent GxE frameworks also explicitly use ensemble/stacking strategies:

- EXGEP framework (stacking for GxE/yield prediction)
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12354955/

## What is still true (and valuable)

Even if not globally new, the method is a **new project-level contribution** in this repository:

1. Specific two-expert blend design for this pipeline.
2. Strict LOEO fold-wise implementation.
3. Fold-conditioned alpha estimation and conservative nested calibration variants.
4. Best observed mean LOEO RMSE among complete local approaches.

## No-hallucination verdict

- **Do not claim**: “completely new in the world.”
- **Valid claim**: “best-performing approach discovered and validated in this repository’s LOEO setup, built from known ensemble principles.”

