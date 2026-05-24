# Oral Defense + Abstract + Journal Sections (2026-05-23)

## 1) One-Page Oral Defense Script

Good [morning/afternoon].

My dissertation contribution is a fixed, externally validated prediction method for genomic-yield settings under a strict confirmatory protocol. The method is an affine combination of three base predictors:

\[
\hat y = 0.80\,\text{pred\_global} + 0.25\,\text{pred\_geno} - 0.05\,\text{pred\_marker}.
\]

The core question was not whether we could optimize performance on one dataset, but whether we could identify a single fixed candidate that generalizes across independent external datasets while passing pre-specified statistical gates.

Our confirmatory criteria were strict and required, per dataset and in both scopes (`all` and `seen_genotypes`):
1. nonnegative mean gain,
2. one-sided paired significance threshold,
3. bootstrap support for positive gain.

The candidate passed this full gate on all four registered external datasets. We then stress-tested the claim in four additional ways.

First, seed robustness: repeated seed perturbation runs preserved the all-dataset pass condition.

Second, independent rebuild: a fresh verification run reproduced the strict-pass outcome.

Third, one-command reproducibility: an operator-style end-to-end script regenerated the key audit state.

Fourth, falsification: when training labels were permuted, confirmatory pass rates collapsed as expected, supporting that performance was tied to real train-side signal rather than a trivial artifact.

We then audited claim strength against prior-art comparators using a reproducible signature-matching framework. Our conclusion is intentionally bounded: we found no exact audited match to this full protocol-signature bundle in the expanded comparator manifest. That supports a high-confidence bounded world-first claim at protocol-signature level.

Equally important, we do not claim universal non-existence. Finite search cannot prove that globally.

So the final contribution is threefold:
1. a fixed deployable candidate method,
2. a strict external confirmation package,
3. a claim-governance framework that distinguishes bounded novelty from absolute novelty.

In short: this work moves from “promising model” to “audited discovery package,” with explicit evidence boundaries and reproducibility guarantees.

---

## 2) Abstract

We report a fixed affine ensemble method for external genomic-yield prediction and a corresponding audit framework for bounded novelty claims. The candidate predictor is defined as
\(\hat y = 0.80\,\text{pred\_global} + 0.25\,\text{pred\_geno} - 0.05\,\text{pred\_marker}\),
held fixed across all evaluations. We evaluated this candidate under a strict confirmatory protocol across four independent external datasets and two evaluation scopes (`all` and `seen_genotypes`), requiring nonnegative mean gain, one-sided paired significance, and bootstrap support for positive gain. The method satisfied the strict gate across all registered datasets. Robustness was further assessed via seed perturbation, independent rebuild verification, and one-command end-to-end reproducibility audit, all of which were passed. A falsification analysis using training-label permutation showed collapse of confirmatory pass rates, consistent with non-artifactual train-side signal. To assess novelty boundaries, we conducted a reproducible comparator-signature audit and evidence-linking workflow over an expanded prior-art manifest. No exact audited comparator match to the full protocol-signature bundle was identified. We therefore support a high-confidence bounded world-first claim at protocol-signature level, while explicitly rejecting universal non-existence claims. This work provides both a practical externally validated method and a transparent claim-governance template for high-stakes model discovery.

---

## 3) Methods + Results (Journal Format)

### Methods

#### Study objective
The primary objective was to discover a single fixed candidate method that would pass strict external confirmatory criteria across multiple independent datasets, rather than optimize a dataset-specific model.

#### Candidate method
We evaluated a fixed affine ensemble of three base predictors:
\[
\hat y = w_g\,\text{pred\_global} + w_{ge}\,\text{pred\_geno} + w_m\,\text{pred\_marker},
\]
with promoted weights:
\(w_g=0.80\), \(w_{ge}=0.25\), \(w_m=-0.05\).

#### External evaluation sets and scopes
The method was evaluated on four registered external datasets under two scopes:
1. `all`
2. `seen_genotypes`

#### Confirmatory gate
A dataset-level pass required all criteria in both scopes:
1. mean gain \(\ge 0\)
2. one-sided paired significance threshold (configured at \(p \le 0.05\))
3. bootstrap support \(P(\text{gain}>0) \ge 0.95\)

A global success claim required all four datasets to pass.

#### Robustness and reproducibility layers
To strengthen discovery validity, we added:
1. seed perturbation robustness audit,
2. independent rebuild verification,
3. one-command reproduce-and-audit workflow.

#### Falsification protocol
We performed permutation-based falsification with three modes:
1. true data (`none`),
2. training-label permutation (`perm_train`),
3. test-label permutation (`perm_test`).

The primary anti-leakage criterion was collapse under `perm_train`.

#### Baseline-strength boundary check
To avoid over-claiming, the candidate was compared not only to global baseline but also to stronger single-expert alternatives and an oracle best-single-expert comparator.

#### Novelty and claim-boundary audit
We implemented an expanded comparator-signature workflow with evidence-linked feature coding and claim-compliance checks. Claim framing was constrained to bounded novelty at protocol-signature level if and only if:
1. strict external evidence held,
2. no exact audited comparator-signature match was found,
3. overstatement phrasing controls were satisfied.

### Results

#### Strict external confirmation
The fixed candidate (`0.80`, `0.25`, `-0.05`) passed strict confirmatory criteria across all four registered external datasets in both scopes.

#### Robustness and reproducibility
Seed perturbation audits preserved all-dataset pass status. Independent rebuild and one-command reproduce-and-audit checks confirmed reproducibility of the promoted claim state.

#### Falsification
Under true data mode, dataset pass rates were retained. Under training-label permutation, pass rates collapsed, supporting dependence on real train-side structure and arguing against a simple leakage-only explanation.

#### Baseline-strength boundary
The candidate robustly outperformed the global baseline but did not uniformly dominate every stronger comparator in every dataset/scope. This supports a robust global fixed-candidate interpretation, not universal per-setting supremacy.

#### Novelty boundary and evidence depth
Expanded comparator audit identified no exact audited match to the full protocol-signature bundle. Evidence-linking depth reached high direct coverage, and high-risk claim phrasing was reduced to zero in the compliance scan.

#### Final claim posture
The total evidence package supports a high-confidence bounded world-first claim at protocol-signature level. Universal non-existence or unqualified first-ever claims remain outside evidentiary scope and are not asserted.
