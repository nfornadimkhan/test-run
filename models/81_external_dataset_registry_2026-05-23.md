# Stage 81 External Dataset Registry (2026-05-23)

## Goal

Identify real external MET/genomic datasets suitable for independent validation of the stage-69/74 discovery candidate.

## Priority shortlist (for immediate execution)

1. **CIMMYT wheat G×E dataset (public repository record)**
- URL: https://data.cimmyt.org/dataset.xhtml?persistentId=hdl%3A11529%2F10714%3B
- Why high priority:
  - explicit G×E genomic prediction context
  - multi-environment trials
  - directly aligned with LOEO evaluation logic

2. **Dryad: Southern US rice multi-environment genomic prediction dataset**
- URL: https://datadryad.org/dataset/doi%3A10.5061/dryad.j9kd51ctd
- Why high priority:
  - explicit multi-environment phenotypes + SNP data
  - independent program/species context
  - good for cross-domain robustness check

3. **Dryad: CIMMYT wheat multi-trait/environment sparse genomic prediction data**
- URL: https://datadryad.org/dataset/doi%3A10.5061/dryad.vx0k6dk3p
- Why high priority:
  - large wheat dataset with multiple environments
  - direct relevance to sparse testing and MET prediction

4. **Dryad: maize multi-trait multi-environment genomic prediction**
- URL: https://datadryad.org/dataset/doi%3A10.5061/dryad.9w0vt4bc2
- Why high priority:
  - independent crop + MET structure
  - tests portability beyond wheat/rice

## Secondary candidates (review for licensing/completeness)

5. **CIMMYT Research Data portal (dataset collection)**
- URL: https://data.cimmyt.org/dataverse/cimmytdatadvn%3Bjsessionid%3D0d3dcc9fcf05d51a4f723f67128d?fq0=subtreePaths%3A%22%2F2%22&fq1=contributorName_ss%3A%22CGIAR+Research+Program+on+Wheat+%28WHEAT%29%22&fq2=subject_ss%3A%22Agricultural+Sciences%22&fq3=contributorName_ss%3A%22CGIAR%22&order=asc&page=1&q=&sort=dateSort&types=datasets%3Adataverses%3Afiles
- Note:
  - use for expanding to 5+ external validations if data extraction is clean.

## Dataset acceptance checklist (must pass before use)

1. Contains genotype-level markers and environment-labeled phenotype records.
2. Has at least 4 distinct environments to permit LOEO-like evaluation.
3. Missingness manageable without leakage-prone imputation.
4. License permits reproducible benchmarking and publication reporting.

## Immediate next step

Create stage-82 data-ingestion checklist and schema harmonization template for these four priority datasets.

