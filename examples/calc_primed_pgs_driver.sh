#!/bin/bash

######################################################## 
##  Program Name  : calc_primed_pgs_driver.sh
##  Study Title   : PRIMED Legacy Project: PRSMix
##  Programmer    : SKMcDonnell, JPSinnwell
##  Function      : Run WDL pipeline to prep genotypes & calculate all scores with ancestry adjustment
##   - Based on Stephanie Gogarten's Cromwell/WDL scripts with modifications to run on HPC Linux cluster (Slurm)
##
##
##  Steps:
##  0. Download harmonized score files
##
##  1. clone cromwell/wdl git repo (Linux implementation, https://github.com/schaidlab/pgsc_calc_wdl)
##     cd /study/dir
##     git clone https://github.com/schaidlab/pgsc_calc_wdl
##
##  2. Create a slurm.conf configuration file specifying your local Slurm parameterization
##     -- See **slurm.example.conf** file as an example and README.slurm for more detail
##
##  3. Generate json templates using womtool-83.jar
##     a. for pgsc_calc_prepare_genomes.wdl
##     b. for calc_scores.wdl
##
##  4. Prepare genotype data
##     a. Update json for this project
##     b. Run pgsc_calc_prepare_genomes.wdl
##
##  5. Run calc_scores.wdl
##     a. Update json for this script (created in 2)
##        NOTE: PGEN/PVAR/PSAM inputs for calc_scores JSON may be dependent on completion of pgsc_calc_prepare_genomes.wdl
##     b. Set add_chr_prefix = TRUE (pgsc_calc_prepare_genomes workflow produces files without prefix)
##
############


STUDYDIR=/research/staging/emerge-bsi
PIPEDIR=/research/staging/emerge-bsi/scripts/pgsc_calc_wdl
SCRIPTDIR=${STUDYDIR}/test_${USER}
CFGDIR=${SCRIPTDIR}/config
mkdir -p ${CFGDIR}

module load java
module load cromwell/83
cromwell=/research/bsi/tools/biotools/cromwell/83

##  Create temp dir 
TMPDIR=/tmp/${USER}/$$
mkdir -p ${TMPDIR}

today=`date +%d%b%Y`
cd ${SCRIPTDIR}

############
##  3. Geneerate json templates using womtool-83.jar
##     - Need to be in the repo directory so all scripts are found
##     - See *.template.json files in repo for examples.

cd ${PIPEDIR}
java -jar -Djava.io.tmpdir=${TMPDIR} ${cromwell}/womtool-83.jar inputs ${PIPEDIR}/pgsc_calc_prepare_genomes.wdl > ${CFGDIR}/pgsc_calc_prepare_genomes.base.json

java -jar -Djava.io.tmpdir=${TMPDIR} ${cromwell}/womtool-83.jar inputs ${PIPEDIR}/calc_scores_scatter.wdl > ${CFGDIR}/calc_scores_scatter.base.json

## Move back to config directory
cd ${CFGDIR}

############
##  4. pgsc_calc_prepare_genomes:
##     a. Update JSON files  
##     b. Run pgsc_calc_prepare_genomes

nohup java -Dconfig.file=${CFGDIR}/slurmjps.conf -Djava.io.tmpdir=${TMPDIR} -jar ${cromwell}/cromwell-83.jar run ${PIPEDIR}/pgsc_calc_prepare_genomes.wdl --inputs ${CFGDIR}/pgsc_calc_prepare_genomes_2chr.json > prep_genome.${today}.log 2>&1 &


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

nohup java -Dconfig.file=${CFGDIR}/slurmjps.conf -Djava.io.tmpdir=${TMPDIR} -jar  ${cromwell}/cromwell-83.jar run ${PIPEDIR}/calc_scores.wdl --inputs ${CFGDIR}/calc_scores_emerge.json > calc_scores.${today}.log 2>&1 &



