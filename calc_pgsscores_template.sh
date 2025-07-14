#!/bin/bash

######################################################## 
##  Program Name  : calc_primed_pgs_driver.sh
##  Function      : Run WDL pipeline to prep genotypes & calculate all scores with ancestry adjustment
##   - Based on Stephanie Gogarten's Cromwell/WDL scripts with modifications to run on HPC Linux cluster (Slurm)
##
##
##  Steps:
##  0. A. Pre-requisites: Download harmonized score files, pre-calculated PCs, make vcf files
##
##     B. clone cromwell/wdl git repo (Linux implementation, https://github.com/schaidlab/pgsc_calc_wdl)
##        cd /study/dir
##        git clone https://github.com/schaidlab/pgsc_calc_wdl
##
##  1. Update a slurm.conf configuration file specifying your local Slurm parameterization
##     -- See **slurm.template.conf** file as an example. See the README section for more details
##
##  2. Update the config/prepare_genomes.template.json file to have run-time settings,
##     executables to plink, and location of vcf files
## 
##  3. Prepare genotype data
##
##  4. Update the calc_scores_scatter.template.json file
##
##  5. Run calc_scores_scatter.wdl
##    


BASEDIR=/full/path/to/git_repo_folder    ## Update this path prior to running!
PIPEDIR=$BASEDIR/pipe         ## Update this path prior to running!
CFGDIR=${BASEDIR}/config

module load java/20.0.2
module load cromwell/83
cromwellbin=`which cromwell`
cromwellpath=`dirname $cromwellbin`
today=`date +%d%b%Y`


## 1. Make a copy of the slurm.template.conf as slurm.conf, and update
cp ${CFGDIR}/slurm.template.conf ${CFGDIR}/slurm.conf

## edit the queue name to that named on slurm system, line 12
## decrease or increase run time, line 23
## replace email on line 25

## 2. Edit the pgsc_calc_prepare_genomes.template.json file

## paths to vcf file
## path to plink executable
## other local run-time settings

############
##  3. run pgsc_calc_prepare_genomes:

nohup java -Dconfig.file=${CFGDIR}/slurm.conf -Djava.io.tmpdir=${TMPDIR} -jar ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/pgsc_calc_prepare_genomes.wdl --inputs ${CFGDIR}/pgsc_calc_prepare_genomes.test.json > prep_genome.${today}.log 2>&1 &

#Johanna: the 2>&1 and nohup are needed together.  Look into if this is senstivie to java versions. Does it work without?

## 4. Edit the calc_scores_scatter.template.json file

## JPS track where it writes the pgen/pvar* files form the log file
## put this in the json
## this line will show the pgen, pvar, and psam file paths that need tobe put into the calc_scores_catter.*.json file.
grep -a2 pvar prep_genome*.log

## we should know where cromwell will put these from "cromwell_executions" directory

## make the next step dependent on this step

############
##  5. calc_scores_scatter:
##     a. Update JSON file:
##        i. Full path location of full-genome PLINK files: calc_scores_scatter.pgen, .pvar, .psam
##       ii. Full path location of PLINK2 and RScript executable
##      iii. Full path location of PCA projection (calc_scores_scatter.pcs)
##       iv. Full path location of R scripts used by workflow. These scripts will be located within the cloned repo folder:
##           1) calc_scores_scatter.aggregate_script
##           2) calc_scores_scatter.adjust_script
##       iv. Submit jobs to generate PGS & perform ancestry-adjustment for each batch of scores
##

nohup java -Dconfig.file=${CFGDIR}/slurm.conf -Djava.io.tmpdir=${TMPDIR} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/calc_scores_scatter.wdl --inputs ${CFGDIR}/calc_scores_scatter.jps.json > calc_scores.${today}.log 2>&1 &



