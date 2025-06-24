# Calculate raw & ancestry-adjusted scores for PRIMED legacy project (PRSMix)

WDL wrapper for calculating PGS and performing ancestry adjustment using Slurm on a high performance computing (HPC) environment. This repo builds off of [Stephanie Gogarten's calc_scores.wdl pipeline](https://github.com/UW-GAC/pgsc_calc_wdl/blob/main/README.md) which calculates scores without using Nextflow. All scripts were authored by Stephanie Gogarten unless otherwise notes. 

## pgsc_calc_prepare_genomes

Standalone workflow to convert VCF to pgen/pvar/psam.

input | description
--- | ---
vcf | Array of VCF files
merge_chroms | Boolean for whether to merge files to a single set of output files with all chromosomes
snps_only | Boolean for whether to keep only SNPs in output

output description
--- | ---
pgen | Array of pgen files
pvar | Array of pvar files
psam | Array of psam files


## calc_scores_scatter

Calculate scores for a set of scorefiles, each containing multiple score models without using Nextflow. Use pgsc_calc_prepare_genomes first to generate files.
Modified from calc_scores.wdl by Shannon McDonnell

input | description
--- | ---
scorefile | Array containing multiple score files
pgen | pgen file
pvar | pvar file
psam | psam file
harmonize_scorefile | Boolean for whether to harmonize scorefile to consistent effect allele (default true)
add_chr_prefix | Boolean for whether to add "chr" prefix to scorefile variant ids to match pvar (default true)

output description
--- | ---
scores | sscore file output by plink
variants | variants included in sscore
overlap | TSV file with fraction of overlapping variants for each score
 
 
## fit_ancestry_model.wdl

Fit mean and variance models for each PG score. Return mean and variance coefficients for ancestry adjustment. 

### ancestry_adjustment.R

R functions used to fit ancestry models and perform ancestry adjustment (also utilized in adjust_scores.wdl)

## subset_score_file.wdl


## adjust_scores.wdl




