#!/bin/bash

######################################################## 
##  Program Name  : submit_calc_score.sh
##  Function      : Run the calc_scores.sh script which submits the calc_scores_scatter.wdl WDL pipeline to Slurm grid
################################

##  1) Modify tempate slurm (/config/slurm.template.conf) and WDL config files (/config/calc_score_scatter.template.json) to reflect your data & system


##  2) Update pipeline inputs below 

PIPEDIR=/full/path/location/of/git/repo
SLURMCFG=/full/path/location/of/updated/slurm.template.conf
WDLCFG=/full/path/location/of/pipeline/config/calc_scores_scatter.template.json
TMPDIR=/tmp/${USER}/$$   ## Update to appropriate /tmp/ space on your system (if submitting on interactive node)
EMAIL=    ##  Fill in your e-mail address for Slurm notifications

##  3) Submit the pipeline (uncomment ONE of the commands below)
##     NOTE: Prior to running, review the Slurm header (#SBATCH lines) in prep_genomes.sh & update to reflect your slurm environment (e.g., queue-names)

sbatch --mail-user=${EMAIL} --mail-type=END,FAIL ${PIPEDIR}/calc_scores.sh ${PIPEDIR} ${SLURMCFG} ${WDLCFG} 


## Optionally, the script can be submitted on an interactive node instead using this syntax
## To submit in this manner, comment out the 'sbatch' command above and uncomment this line, save & run this script: 
## nohup /bin/bash ${PIPEDIR}/calc_scores.sh ${SLCFG} ${CSCFG} ${TMPDIR} > calc_scores.${today}.log 2>&1 &





