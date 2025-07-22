#!/bin/bash

######################################################## 
##  Program Name  : submit_prep_genomes.sh
##  Function      : Run the prep_genomes.sh script which submits the pgsc_calc_prepare_genomes.wdl WDL pipeline to Slurm grid
################################

##  1) Modify tempate slurm (/config/slurm.template.conf) and WDL config file (/config/pgsc_calc_prepare_genomes.template.json) to reflect your data & system


##  2) Update pipeline inputs below 

PIPEDIR=/full/path/location/of/git/repo
SLURMCFG=/full/path/location/of/updated/slurm.template.conf
WDLCFG=/full/path/location/of/pipeline/config/pgsc_calc_prepare_genomes.template.json
TMPDIR=/tmp/${USER}/$$   ## Update to appropriate /tmp/ space on your system (if submitting on interactive node)
EMAIL=    ##  Fill in your e-mail address for Slurm notifications

##  3) Submit the pipeline (uncomment ONE of the commands below)
##     NOTE: Prior to running, review the Slurm header (#SBATCH lines) in prep_genomes.sh & update to reflect your slurm environment (e.g., queue-names)

sbatch --mail-user=${EMAIL} --mail-type=END,FAIL ${PIPEDIR}/prep_genomes.sh ${PIPEDIR} ${SLURMCFG} ${WDLCFG} 


## Optionally, the script can be submitted on an interactive node instead using this syntax
## To submit in this manner, comment out the 'sbatch' command above and uncomment this line, save & run this script: 
## nohup /bin/bash ${PIPDIR}/prep_genomes.sh ${SLCFG} ${CSCFG} ${TMPDIR} > prep_genomes.${today}.log 2>&1 &





