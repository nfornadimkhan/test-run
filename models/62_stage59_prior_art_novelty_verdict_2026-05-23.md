# Stage 62 Prior-Art Novelty Verdict for Stage-59 Candidate (2026-05-23)

## Candidate under audit

Stage-59 fixed candidate:
- fold-level predicted coefficients with shrink/caps
- prediction form:
  - `pred = pred_meta + u1(e)*delta + u2(e)*sign(delta)*sqrt(abs(delta))`
  - where `delta = gmean_shrunk - baseline`

## Search objective

Find direct prior-art matches for:
1. two-regime / corrected meta-prediction in genomic GxE prediction,
2. environment-conditioned nonlinear correction term of `sign(delta)*sqrt(abs(delta))`,
3. same structural composition on top of MET genomic prediction baseline.

## Targeted prior-art pass (2026-05-23)

Representative sources found:
- MoEGP (mixture-of-experts genomic prediction):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12958669/
- MeNet (mixed-effect deep neural network for multi-environment genomic prediction):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC12983247/
- broader nonlinear/MET genomic prediction literature:
  - https://www.nature.com/articles/s41437-020-00353-1
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC9210316/
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC6723142/

## Overlap classification

- Family-level overlap: **Yes**
  - nonlinear genomic prediction, MoE/gating, multi-environment extensions are established.
- Exact structural match to stage-59 equation in audited set: **Not found**
  - no direct audited source with this same correction decomposition and coefficient strategy.

## Claim boundary for stage-59

Allowed:
- “No exact match found in audited sources as of 2026-05-23.”
- “Method appears structurally distinct from the project’s earlier convex blend baseline.”

Not allowed:
- “Proven world-first in existence.”
- “No prior art in related method families.”

## Combined status (novelty + evidence gates)

- Novelty plausibility for exact formulation: **positive but not globally proven**.
- Empirical robustness: very strong practical gains, but inferential stability gates remain borderline in repeated subset audit.

## Verdict

Stage-59 is a high-value candidate with plausible exact-form novelty and strong performance uplift, but strict world-first declaration remains unproven under current evidence protocol.

