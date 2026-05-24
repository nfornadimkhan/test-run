# Multi-environment evaluation and genomic prediction of agronomic traits in the southern US rice genepool

Dataset DOI: [10.5061/dryad.j9kd51ctd](https://doi.org/10.5061/dryad.j9kd51ctd)

## Description of the data and file structure

This dataset includes rice SNP data in HapMap format and phenotypic measurements of the rice in the field. 

For genotyping, this rice panel was grown in a greenhouse in Stuttgart, Arkansas. Leaf disks were collected and sent to Agriplex Genomics for genotyping using the Agriplex 550 SNP Rice panel designed for GS using southern US rice germplasm (Cerioli et al., 2022). We acknowledge and thank the team at Louisiana State University that facilitated genotyping: Brijesh Angira, Tommaso Cerioli, Chris Hernandez, and Adam Famoso. Additionally, we thank Melissa Jia (Dale Bumpers National Rice Research Center) for obtaining leaf samples and preparing them for genotyping.

For phenotyping, the rice was grown in the field in three locations in 2008: at the Delta Research Extension Center in Stoneville, Mississippi, USA; at the Dale Bumpers Rice Research Center in Stuttgart, Arkansas, USA, and at the H. Rouse Caffey Rice Research Station in Crowley, Louisiana, USA. 

### Files and variables

#### File: RiceCAP_named_Sorted.hmp.txt

**Description:** Genotype file in HapMap format.

* rs#: SNP identifier
* alleles: alleles present at that SNP
* chrom: chromosome where that SNP is located
* pos: the position of the SNP on the chromosome
* strand: The orientation of the SNP on the strand (+ = forward, - = reverse)
* assembly#: the version of the reference sequence assembly (NA = omitted)
* center: the name of the center that genotyped this sequence (NA = omitted)
* protLSID: HapMap protocol identifier (NA = omitted)
* assayLSID: genotyping assay identifier (NA = omitted)
* panelLSID: panel identifier (NA = omitted)
* QCcode: quality control (NA = omitted)
* Remainder of the columns are the sample names (the naming is consistent with phenotying file)

For more information on the HapMap format for genotypic data, please see this white paper written and distributed by the ESALQ/USP Department of Genetics Statistical Genetics Lab: [https://statgen.esalq.usp.br/site/Hapmap-and-VCF-formats-and-its-integration-with-onemap/#:~:text=The%20file%20format%20estabilished%20through,chromosome%20or%20a%20general%20file.&text=rs%23%20contains%20the%20SNP%20identifier,the%20list%20of%20sample%20names](https://statgen.esalq.usp.br/site/Hapmap-and-VCF-formats-and-its-integration-with-onemap/#:~:text=The%20file%20format%20estabilished%20through,chromosome%20or%20a%20general%20file.&text=rs%23%20contains%20the%20SNP%20identifier,the%20list%20of%20sample%20names).

#### File: Filtered_phenotypes_RiceCAPAmp-accessible.csv

**Description:** Phenotypic data for each genotype. The naming convention matches the associated genotype file.

* index: row index number
* Master List No.: index number on the master list
* comments or corrections made: comments made during phenotyping and data curation
* Location (1 = MS; 2 = AR; 3 = LA): location where a phenotype was measured (1 = Delta Research Extension Center in Stoneville, Mississippi, USA; 2 = Dale Bumpers Rice Research Center in Stuttgart, Arkansas, USA; 3 = H. Rouse Caffey Rice Research Station in Crowley, Louisiana, USA)
* AMP Entry#: index number in an internal naming convention
* ID#: ID number for the measured rice genotype (matches with genotype file)
* VARIETY/CROSS: Pedigree data for this rice genotype
* PLOT#: field plot number
* REP#: plot replicate number (three plants were measured per plot/rep combination)
* PLANTDATE: the day of the year in 2008 when the rice was planted
* EMERGDATE: the day of the year in 2008 when rice emergence was observed
* HEADDATE: the day of the year in 2008 when rice heading was observed
* PLANTHT 1 (cm): the plant height of the first plant in the measured plot/rep
* PLANTHT 2 (cm): the plant height of the second plant in the measured plot/rep
* PLANTHT 3 (cm): the plant height of the third plant in the measured plot/rep
* MEANHT (cm): the mean height of the three plants measured in the plot/rep
* MATDATE: the day of the year in 2008 when rice maturity was observed
* TILL#PLANT 1: the number of tillers observed for the first plant in this plot/rep
* TILL#PLANT 2: the number of tillers observed for the second plant in this plot/rep
* TILL#PLANT 3: the number of tillers observed for the third plant in this plot/rep
* TILL#MEAN: the mean number of tillers observed for the three plants
* PAN LENGTH PLANT 1 (cm): the panicle length measured for the first plant in this plot/rep
* PAN LENGTH PLANT 2 (cm): the panicle length measured for the second plant in this plot/rep
* PAN LENGTH PLANT 3 (cm): the panicle length measured for the third plant in this plot/rep
* PAN LENGTH MEAN: the mean panicle length for the three plants measured in this plot/rep
* SEED #/PAN PLANT 1: the number of seeds counted per panicle on the first plant in this plot/rep
* SEED #/PAN PLANT 2: the number of seeds counted per panicle on the second plant in this plot/rep
* SEED #/PAN PLANT 3: the number of seeds counted per panicle on the third plant in this plot/rep
* SEED #/PAN MEAN: the mean number of seeds counted per panicle for the three plants in this plot/rep
* SEED SAMPLE WT  (g) / PANICLE PLANT 1: the weight of the seeds counted per panicle on the first plant in this plot/rep
* SEED SAMPLE WT  (g) / PANICLE PLANT 2: the weight of the seeds counted per panicle on the second plant in this plot/rep
* SEED SAMPLE WT  (g) / PANICLE PLANT 3: the weight of the seeds counted per panicle on the third plant in this plot/rep
* SEED SAMPLE WT  (g) / PANICLE MEAN: : the mean weight of the seeds counted per panicle on the three plants in this plot/rep
* TOTAL SEED WEIGHT (g) PLANT 1: the total weight of the seeds counted on the first plant in this plot/rep
* TOTAL SEED WEIGHT (g) PLANT 2: the total weight of the seeds counted on the second plant in this plot/rep
* TOTAL SEED WEIGHT (g) PLANT 3: the total weight of the seeds counted on the third plant in this plot/rep
* TOTAL SEED WEIGHT (g) MEAN: the mean total weight of the seeds counted on the three plants in this plot/rep
* Total Biomass (g): the total biomass measured
* Days to EMERG: the number of days from planting to emergence
* Days to HEAD: the number of days from planting to heading
* Days to MATURITY: the number of days from planting to maturity
* Grainfill days: the number of days from heading to maturity

Missing data is denoted with a "."

## Code/software

The genotype file can be opened with TASSEL software: [https://tassel.bitbucket.io/](https://tassel.bitbucket.io/) or any HapMap compatible software. Note that the "#" character in the header may need to be removed to open this file in some softwares, for example R. The phenotype file can be opened using  a spreadsheet software.
