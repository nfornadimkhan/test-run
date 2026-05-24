# Stage 113 Operator Reproduce Runbook (2026-05-23)

## Purpose

Rebuild and verify the promoted world-first candidate evidence in one command.

## Preconditions

- Workspace path unchanged:
  - `/Users/neon/Documents/Nadim's Brain`
- Required scripts and external_validation artifacts present.

## Command

```bash
Rscript /Users/neon/Documents/Nadim's\ Brain/analysis/prediction-validation/113_reproduce_and_audit_worldfirst_candidate.R
```

## Expected outputs

- Execution log:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/113_reproduce_audit/113_execution_log.csv`
- Audit summary:
  - `/Users/neon/Documents/Nadim's Brain/analysis/outputs/prediction_yield/external_validation/run_queue/113_reproduce_audit/113_audit_summary.csv`

## Pass condition

In `113_audit_summary.csv` the following must all be `TRUE`:
- `all_commands_ok`
- `independent_verify_ok`
- `tracker_status_ok`
- `final_audit_pass`

## Promoted candidate pinned by run

- `w_global=0.80`
- `w_geno=0.25`
- `w_marker=-0.05`
- seeds:
  - `marker_seed=4242`
  - `boot_seed_all=9601`
  - `boot_seed_seen=9602`
