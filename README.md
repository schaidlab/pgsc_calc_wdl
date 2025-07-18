
## Purpose: Calculate raw & ancestry-adjusted scores for PRIMED legacy project (PRSMix)

WDL wrapper for calculating PGS and performing ancestry adjustment using Slurm on a high performance computing (HPC) environment. This repo builds off of [Stephanie Gogarten's calc_scores.wdl pipeline](https://github.com/UW-GAC/pgsc_calc_wdl/blob/main/README.md) which calculates scores without using Nextflow. All
 scripts were authored by Stephanie Gogarten unless otherwise notes. 


# Steps at a high level for Slurm HPC, we offer these general steps

0. Pre-requisite files
   A. Harmonized score files
   B. Pre-calculate ancestry-adjusted PCs, save in txt file
   C. File(s) of all sample variants (VCF or PGEN)

1. Activate Tools and Scripts
   A. Activate java (>17.0.1), plink(>=2.0.0), cromwell(>=83), Rscript (>= 4.2.0)
   B. Clone git repo [SchaidLab repo](https://github.com/schaidlab/pgsc_calc_wdl)

2. Edit the config/slurm.example.config file specifying your local Slurm parameterization.


3. If chromosome-specific VCF files:
   A. Edit the config/prepare_genomes.template.json file to have run-time settings, executables to plink, and location of vcf file(s)
   B. Run the prepare_genomes.wdl script


4. Run calc_scores_scatter
   A. Edit the config/calc_scores_scatter.template.json file with the processed psam/pvar files
   B. Run the calc_scores_scatter.wdl script


# Expanded Details for editing json and configure files.


## 2. Editing the config/slurm.template.conf file
-- User will need to modify:

      a. root (where cromwell will run and pipeline output will be located, line 9)
      b. Queue name (line 12)
      c. You may need to update --time depending on your queue maxtime (sinfo will show partitions available on your system). (line 23)
      		- <<Insert time estimates from Mayo runs for each step>>
      d. Confirm slurm mail-type used by your institution (line 24, e.g., BEGIN, END, FAIL). This dictates when you will receive e-mails for each grid job. 
      e. User e-mail (line 25)

## 3. Editing config/pgsc_calc_prepare_genomes.template.json
-- User will need to modify:

      a. path to plink on your system
      b. full path and file name of vcf file(s). Typically these are split by chromosome, in which case a comma-separated list of vcf files is needed. 
      c. optional, other parameter settings for memory and cpus.


##  4. Updating the config/calc_scores_scatter.template.json file

-- User will need to modify:

	Data parameters:
 
		a. score file locations (harmonized files from Anvil)
		b. path to projection PCs for your samples 
		c. pgen/psam/pvar file locations (output from pgsc_calc_prepare_genomes)
	
 	Tool paths: 
	
  		g. RSCRIPT path on your system
		h. PLINK2 path on your system
		  adjust_script path (this will be located in the cloned repo /pipe/ folder)
		f. aggregate_script path (this will be located in the cloned repo /pipe/ folder)
  	
   	d. aggregate_results.prefix to your desired output file names (suggest using PRIMED cohort name, e.g., eMERGE)
	 

