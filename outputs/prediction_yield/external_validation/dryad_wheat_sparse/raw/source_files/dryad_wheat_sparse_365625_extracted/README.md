# Data for: Multi-Trait/Environment Sparse Genomic Prediction using the SFSI R-package

Dataset DOI: [10.5061/dryad.vx0k6dk3p](10.5061/dryad.vx0k6dk3p)

## Data set overview

This data set is from CIMMYTs Global Wheat Program and includes adjusted phenotypic records of grain yield (ton/ha) from n=3,731 wheat (*Triticum aestivum*) lines evaluated at four environmental conditions (B2I, B5I, MEL, and LHT), and marker data for 9,045 SNPs. This data set is a subset, corresponding to the lines that have data in the four environments, from the full data set described and analyzed by Perez-Rodriguez *et al.* (2017) and Lopez-Cruz & de los Campos (2021).

### Data structure

The data set consists of two `.csv` files:

* `pheno.csv`: Phenotypic data file consists of a matrix with grain yield records for 3,731 wheat lines (in rows) evaluated at four environments (B2I, B5I, MEL, and LHT) in columns.
* `geno.csv`: Genotypic data (geno.csv) is a matrix with 9,045 SNP markers (in columns) for all the 3,731 wheat lines (in rows)

## Full data description

### Experimental data

The original data set comprised a total of 29,484 lines derived from years 2009 through 2016 evaluated at the CIMMYTs experimental station in Ciudad Obregon, Mexico. Lines were evaluated under six environmental conditions representing a combination of planting system (bed vs. flat, the later referred to as melgas), number of irrigations (2, 5 irrigations or drip irrigation), and sowing date (optimum, late or early planting):

* B2I: bed planting and two irrigations
* B5I: bed planting and five irrigations
* MEL: melgas flat planting and five irrigations
* LHT: late heat
* DRB: bed planting and drip irrigation
* EHT: early heat

Grain yield trials were established in an alpha-lattice design with three replicates into incomplete block. Moisture-standardized grain yield (ton/ha) was measured as the total yield plot.

**Adjusted means**. Least-square means for each line within environmental condition were obtained using mixed-effect models that include a fixed intercept and the random effects of trial, block (within trial), and replicate (within trial).

### Genotypic data

Lines were were genotyped using GBS (Genotyping-by-sequencing) technology which produced 42,706 SNP markers. SNPs were filtered by removing those with more than 70% of missing values and those with minor allele frequency (MAF) lower than 5%. A total of 9,045 SNPs were retained after applying these filters. Markers scores that were missing were imputed with the sample mean of lines at the corresponding loci.

### References

Perez-Rodriguez, P., Crossa, J., Rutkoski, J., Poland, J., Singh, R., Legarra, A., Autrique, E., Campos, G. de los, Burgueño, J., & Dreisigacker, S. (2017). Single-Step Genomic and Pedigree Genotype x Environment Interaction Models for Predicting Wheat Lines in International Environments. *The Plant Genome*, 10(2), 115.

Lopez-Cruz, M., & de los Campos, G. (2021). Optimal breeding-value prediction using a Sparse Selection Index. *Genetics*, 218(1), 110.
