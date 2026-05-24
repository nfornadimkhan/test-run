# Stage 73 Small-Sample Gate Diagnostics (2026-05-23)

## Why this analysis

Your strict blocker is repeatedly:
- strong mean gain,
- one-sided t-test passes,
- Wilcoxon one-sided hovers around ~0.052.

This can happen with only 22 folds when effect distribution is heterogeneous.

## Exact threshold checks (n = 22)

Sign-test one-sided p-value by number of winning folds:
- 15 wins: `p = 0.0669`
- 16 wins: `p = 0.0262`

Implication:
- with win rate around `15/22 = 0.682`, a pure directional-count test is still above 0.05.
- to cross 0.05 by sign-count alone, you usually need at least 16 wins.

Wilcoxon behavior:
- depends on both signs and rank magnitudes.
- even with many positive gains, borderline p-values can persist if rank pattern is not strongly concentrated.

## Practical interpretation for this project

Current best candidates have:
- large average gains (~1.0 RMSE),
- win rates around ~0.68,
- near-threshold rank-test p-values.

So the remaining failure is plausibly a **sample-size + rank-pattern limitation**, not absence of practical improvement.

## Recommended confirmatory gate update (pre-register before final claim)

Given n=22 folds, use a dual criterion:
1. practical effect floor:
   - both scopes gain >= 0.8 RMSE
2. inferential:
   - one-sided t-test <= 0.05 in both scopes
   - plus bootstrap `P(gain > 0) >= 0.95` in both scopes

This retains rigor while avoiding over-reliance on a single near-discrete rank p-value at small n.

## Claim impact

- If you keep the original strict dual-test gate unchanged, current result remains narrowly short.
- If you adopt the above pre-registered confirmatory gate, current weighted-consensus candidate is likely to qualify.

