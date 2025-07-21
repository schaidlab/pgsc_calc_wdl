#!/bin/bash
#SBATCH -p cpu-short
#SBATCH -J calc_prs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 12
#SBATCH --mem=16G
#SBATCH -t 48:00:00

######################################################## 
##  Program Name  : run_calc_score.sh
##  Function      : Run calc_scores_scatter.wdl WDL pipeline to calculate all scores with ancestry adjustment
##   - Based on Stephanie Gogarten's Cromwell/WDL scripts with modifications to run on HPC Linux cluster (Slurm)
##
##  Arguments:
##   - Slurm config file
##   - WDL config file for calc_scores_scatter.wdl, the edited version of calc_scores_scatter.template.json
##   - TMPDIR (?) temp space used by Java
##
##
##  NEED THESE SET IN YOUR XTERM BEFORE THE SBATCH COMMAND
##  UNCOMMENT AND EXECUTE HERE TO THE LOGDIR LINE. Then the sbatch cmd
##
##  SLCFG=/research/staging/emerge-bsi/test_jps/coderepo/config/slurm.conf
##  CSCFG=/research/staging/emerge-bsi/test_jps/coderepo/config/calc_scores_scatter.test.json
##  TMPDIR=/tmp/${USER}/$$
##  mkdir -p ${TMPDIR}
##  today=$(date +%Y%m%d)
##  EMAIL=sinnwell.jason@mayo.edu
##  LOGDIR=/research/staging/emerge-bsi/test_jps/logs
##
##   1) interactive node - this will launch jobs to Slurm grid:
###   nohup /bin/bash run_calc_scores.sh ${SLCFG} ${CSCFG} ${TMPDIR} > calc_scores.${today}.log 2>&1 &
##
##   2) direct submission to grid (TMPDIR argument is not required)
##   sbatch -e ${LOGDIR}/%x.o%j.stdout -e ${LOGDIR}/%x.o%j.stderr --mail-user=${EMAIL} --mail-type=FAIL jps_run_calc_scores.sh ${SLCFG} ${CSCFG} ${TMPDIR}
################################
if [ $# < 2 ]; then
    echo "Usage: run_calc_scores.sh <<SLURM_CONFIG>> <<calc_scores_CONFIG>> <<TMPDIR>>"
    exit
else
    echo "Usage: run_calc_scores.sh $@";
    SLURMCFG=$1
    WDLCFG=$2
fi

if [ $# == 3]; then 
    ##  TMPDIR is required if submitting interactively
    TMPDIR=$3
fi

if [ ! -s "${SLURMCFG}" ]; then
    echo "Slurm config file does not exist"
    kill $PPID
    exit
fi

if [ ! -s "${WDLCFG}" ]; then
    echo "WDL config file does not exist"
    kill $PPID
    exit
fi

BASEDIR=/research/staging/emerge-bsi/primed_repos/skm_pgsc_calc    ## Update this path prior to running!
PIPEDIR=$BASEDIR/pipe         ## Update this path prior to running!

module load java/20.0.2 || { echo "Failed to load Java module" >&2; exit 1; }
module load cromwell/83 || { echo "Failed to load Cromwell module" >&2; exit 1; }
cromwellbin="$(command -v cromwell)"   ##  use command -v instead of which ? 
if [ ! -x "$cromwellbin" ]; then
    echo "Cromwell binary not found or not executable at $chromwellbin" >&2
    exit 1
else
    cromwellpath="$(dirname $cromwellbin)"
fi
today="$(date +%Y%m%d)"
export cromwellbin cromwellpath today

## Run pipeline
if [ -z "$SLURM_JOB_ID" ];  then
    echo "Running interactively"

    mkdir -p ${TMPDIR}
    nohup java -Dconfig.file=${SLURMCFG} -Djava.io.tmpdir=${TMPDIR} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/calc_scores_scatter.wdl --inputs ${WDLCFG} > calc_scores.${today}.log 2>&1 &

else
    echo "Running under Slurm (job ID: $SLURM_JOB_ID)"
    
    java -Dconfig.file=${SLURMCFG} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/calc_scores_scatter.wdl --inputs ${WDLCFG}

    #java -Dconfig.file=${SLURMCFG} -Djava.io.tmpdir=${TMPDIR} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/calc_scores_scatter.wdl --inputs ${WDLCFG}

fi





