
## Purpose: Calculate raw & ancestry-adjusted scores for PRIMED legacy project (PRSMix)

WDL wrapper for calculating PGS and performing ancestry adjustment using Slurm on a high performance computing (HPC) environment. This repo builds off of [Stephanie Gogarten's calc_scores.wdl pipeline](https://github.com/UW-GAC/pgsc_calc_wdl/blob/main/README.md) which calculates scores without using Nextflow. All
 scripts were authored by Stephanie Gogarten unless otherwise notes. 


# General steps to run on Slurm HPC 

1. Pre-requisite files
   1. Harmonized score files (download from AnVil)
   2. Pre-calculate ancestry-adjusted PCs, save in txt file
   3. Sample genotype files (VCF or PGEN)

2. Activate Tools and Scripts
   1. Activate java (>17.0.1), plink(>=2.0.0), cromwell(>=83), Rscript (>= 4.2.0)
   2. Clone git repo [SchaidLab repo](https://github.com/schaidlab/pgsc_calc_wdl)

3. Edit the /config/slurm.example.config file specifying your local Slurm parameterization.

4. Run pgsc_calc_prepare_genomes pipeline (if chromosome-specific VCF files):
   1. Edit the /config/prepare_genomes.template.json file to have run-time settings, executables to plink, and location of vcf file(s)
   2. Run the /pipe/pgsc_calc_prepare_genomes.wdl pipeline 

5. Run calc_scores_scatter pipeline
   1. Edit the /config/calc_scores_scatter.template.json file (See expanded notes in section 5.)
   2. Run the calc_scores_scatter.wdl script. See run_calc_scores.sh for example submission script. 


# Expanded Details for editing json and configure files.


## 3. Editing the config/slurm.template.conf file
User will need to modify:
1. root (where cromwell will run and pipeline output will be located, line 9)
2. Queue name (line 12)
3. You may need to update --time depending on your queue maxtime (sinfo will show partitions available on your system). (line 23)
   - Mayo test run for eMERGE (100k subjects) utilized these memory thresholds: 
4. Confirm slurm mail-type used by your institution (line 24, e.g., BEGIN, END, FAIL). This dictates when you will receive e-mails for each grid job. 
5. User e-mail (line 25)

## 3. Editing config/pgsc_calc_prepare_genomes.template.json
User will need to modify:
1. path to plink2 executable on your system
2. full path and file name of vcf file(s). Typically these are split by chromosome, in which case a comma-separated list of vcf files is needed. 
3. optional, other parameter settings for memory and cpus.

##  4. Updating the config/calc_scores_scatter.template.json file
User will need to modify:
1. Data parameters:
   - score file locations (harmonized files from Anvil)
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
   - harmonize_scorefile: false (ANVIL score files have already been harmonized)
   - ancestry_adjust: true 
   - add_chr_prefix: false (ANVIL harmonized score files do not contain 'chr' prefix, so set to false)
   
	 

