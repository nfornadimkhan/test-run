# Stage 82 External Ingestion and Schema Checklist (2026-05-23)

## Purpose

Standardize external datasets into a leakage-safe schema so stage-69/74 candidate can be evaluated consistently across independent datasets.

## A) Required canonical columns

1. `geno_id` (genotype identifier)
2. `env_id` (environment identifier)
3. `year` (if available)
4. `location` (if available)
5. `trait_value` (target phenotype)
6. marker matrix (SNP features or genomic relationship proxy)
7. optional environmental covariates (`ec_*`)

## B) Ingestion checklist per dataset

1. Verify license allows reproducible benchmarking/publication.
2. Load raw phenotype and genotype files without modifying originals.
3. Confirm unique key integrity:
   - no duplicated `(geno_id, env_id, trait)` rows after cleaning.
4. Document missingness:
   - `% missing trait`
   - `% missing markers`
   - `% missing EC covariates`
5. Remove rows impossible for evaluation (missing `geno_id`, `env_id`, `trait_value`).

## C) Leakage controls (mandatory)

1. Build folds on `env_id` first (LOEO).
2. Any imputation/scaling parameters must be fit on training folds only.
3. Any genotype history statistics must exclude held-out environment.
4. External covariate engineering must not use target fold outcomes.

## D) Harmonization rules

1. Normalize column names to canonical fields.
2. Convert IDs to strings; avoid accidental numeric coercion.
3. Standardize trait units where possible (record transformation if applied).
4. Preserve raw-to-canonical mapping table for audit.

## E) Minimum dataset viability gate

Dataset enters evaluation only if:
1. `n_env >= 4`
2. at least 1,000 non-missing phenotype rows (or justified exception)
3. marker/genomic predictor available for >=80% of rows
4. LOEO folds each have non-empty training and test sets

## F) Output artifacts required per dataset

1. `*_canonical.csv` (phenotype + EC schema)
2. `*_marker_manifest.csv` (marker source, dimensionality, preprocessing)
3. `*_fold_map.csv` (LOEO fold assignment)
4. `*_ingestion_qc.md` (all checks + pass/fail)

## G) Next execution step

Create stage-83 dataset-specific ingest scripts for:
1. CIMMYT wheat G×E dataset (`hdl:11529/10714`)
2. Dryad southern US rice MET dataset (`10.5061/dryad.j9kd51ctd`)

