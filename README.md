
## Purpose: Calculate raw & ancestry-adjusted scores for PRIMED legacy project (PRSMix)

WDL wrapper for calculating PGS and performing ancestry adjustment using Slurm on a high performance computing (HPC) environment. This repo builds off of [Stephanie Gogarten's calc_scores.wdl pipeline](https://github.com/UW-GAC/pgsc_calc_wdl/blob/main/README.md) which calculates scores without using Nextflow. All
 scripts were authored by Stephanie Gogarten unless otherwise noted. 


# General steps to run on Slurm HPC 

1. Pre-requisite files
   1. Harmonized score files (download from AnVIL)
   2. Pre-calculate ancestry-adjusted PCs, save in txt file
   3. Sample genotype files (VCF or PGEN)

2. Activate Tools and Scripts
   1. Activate java (>17.0.1), plink(>=2.0.0), cromwell(>=83), Rscript (>= 4.2.0)
   2. Clone git repo [SchaidLab repo](https://github.com/schaidlab/pgsc_calc_wdl)

3. Edit the /config/slurm.example.config file specifying your local Slurm parameterization.

4. Run **pgsc_calc_prepare_genomes** pipeline; a standalone workflow to convert VCF to pgen/pvar/psam. 

input | description
--- | ---
vcf | Array of VCF files
merge_chroms | Boolean for whether to merge files to a single set of output files with all chromosomes
snps_only | Boolean for whether to keep only SNPs in output

output | description
--- | ---
pgen | Array of pgen files
pvar | Array of pvar files
psam | Array of psam files

5. Run **calc_scores_scatter** pipeline to calculate scores and perform ancestry adjustment without using Nextflow. Use pgsc_calc_prepare_genomes first to generate files.

input | description
--- | ---
scorefile | Array of harmonized score files
pgen | full-genome pgen file
pvar | full-genome pvar file
psam | full-genome psam file
pcs  | projected PCs 
harmonize_scorefile | Boolean for whether to harmonize scorefile to consistent effect allele (default true)
ancestry_adjust | Boolean for whether to perform ancestry adjustment (default true)
add_chr_prefix | Boolean for whether to add "chr" prefix to scorefile variant ids to match pvar (default false)
PLINK2 | Full path to plink2 executable
RSCRIPT | Full path to RSCRIPT executable
adjust_script | path to ancestry_adjustment.R script on local system
aggregate_script | path to aggregate_scores.R script on local system
aggregate_results.prefix | Prefix used to name all aggregated output files 

output | description
--- | ---
{prefix}_adjusted_scores.tsv | TSV file containing all ancestry adjusted scores aggregated across all harmonized score files
{prefix}_raw_sum_scores.tsv | TSV file containing all raw SUM PRS aggregated across all harmonized score files
{prefix}_raw_avg_scores.tsv | TSV file containing all raw AVG PRS aggregated across all harmonized score files
{prefix}_overlap.tsv | TSV file containing overlap metrics for all PRS

# Expanded Details 


## 3. Updating the /config/slurm.template.conf file
User will need to modify:
1. root (where cromwell will run and pipeline output will be located, line 9)
2. Queue name (line 12). The `sinfo` command can be used to see available queue names. 
3. You may need to update the time grid parameter (`--time`) depending on your queue maxtime (`sinfo` will show partitions and time limits available on your system). (line 23)
4. Confirm slurm mail-type options used by your institution (line 24, e.g., BEGIN, END, FAIL). This dictates when you will receive e-mails for each grid job. 
5. User e-mail (line 25)

## 4. Run pgsc_calc_prepare_genomes WDL pipeline

###  a. Update the /config/pgsc_calc_prepare_genomes.template.json
 
User will need to modify:
1. path to plink2 executable on your system
2. full path and file name of vcf file(s). Typically these are split by chromosome, in which case a comma-separated list of vcf files is needed. 
3. optional, other parameter settings for memory and cpus.

###  b. Submit pipeline 

The shell wrapper `prep_genomes.sh` enables required tools and runs the WDL pipeline pgsc_calc_prepare_genomes.WDL. To run the pipeline using this shell wrapper:   

1. Update Slurm queue name in prep_genomes.sh to reflect a queue available on your system:  `#SBATCH -p cpu-short`. 
	- To submit directly to Slurm queue:
	sbatch --mail-user=<EMAIL.ADDRESS> --mail-type=FAIL prep_genomes.sh <<PIPELINE_DIR>> <<SLURM_CONFIG>> <<pgsc_calc_prepare_genomes JSON>>
	
	*or*
	
1. Follow directions in submit_prep_genomes.sh to update repo location and config files
2. Update Slurm queue name in prep_genomes.sh to reflect a queue available on your system:  `#SBATCH -p cpu-short`. 
3. Save both updated scripts (prep_genomes.sh and submit_prep_genomes.sh) 
4. Run submit_prep_genomes.sh by submitting this line in a linux shell:
   ./submit_prep_genomes.sh 
   

## 5. Run calc_score_scatter WDL pipeline

###  a. Update the /config/calc_scores_scatter.template.json file

User will need to modify:
1. Data parameters:
   - score file locations (harmonized files from AnVIL)
   - path to projection PCs for your samples 
   - pgen/psam/pvar file locations: 
	   - The merged PGEN files will be located in the output from the pgsc_calc_prepare_genomes pipeline, i.e., /`root`/pgsc_calc_prepare_genomes/`random_string`/call-merge_files/execution/merged.[pvar/pgen/psam])
	   - `root` is the output path you define in the slurm config file
	   - `random_string` is a string of numbers and characters defined by cromwell
	   
2. Tool paths:
   - RSCRIPT path on your system
   - PLINK2 path on your system
   - adjust_script path (this will be located in the cloned repo: /pipe/ancestry_adjustment.R)
   - aggregate_script path (this will be located in the cloned repo /pipe/aggregate_scores.R)

3. Other parameters:
   - aggregate_results.prefix: Prefix string used to name final output files (suggest using PRIMED cohort name, e.g., eMERGE)
   - harmonize_scorefile: `true` (ANVIL score files need to be harmonized)
   - ancestry_adjust: `true`
   - add_chr_prefix: `false` (ANVIL harmonized score files do not contain 'chr' prefix, so set to false)
   
###  b. Submit pipeline (via submit_calc_scores.sh)

The shell wrapper `calc_scores.sh` enables required tools and runs the WDL pipeline calc_scores_scatter.WDL. To run the pipeline using this shell wrapper:   

1. Update Slurm queue name in calc_scores.sh to reflect a queue available on your system:  `#SBATCH -p cpu-short`.
   	- To submit directly to Slurm queue:
	sbatch --mail-user=<EMAIL.ADDRESS> --mail-type=FAIL calc_scores.sh <<PIPELINE_DIR>> <<SLURM_CONFIG>> <<calc_scores_scatter JSON>>
	
	*or*
	
	
1. Update Slurm queue name in calc_scores.sh to reflect a queue available on your system:  `#SBATCH -p cpu-short`.
2. Follow directions in submit_calc_scores.sh to update repo location and config files
3. Save both updated scripts (calc_scores.sh and submit_calc_scores.sh) 
4. Run submit_calc_genomes.sh by submitting this line in a linux shell:
   ./submit_calc_genomes.sh 
   

