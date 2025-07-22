#!/bin/bash
#SBATCH -p cpu-short
#SBATCH -J calc_prs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 12
#SBATCH --mem=16G
#SBATCH -t 48:00:00

######################################################## 
##  Program Name  : calc_score.sh
##  Function      : Run calc_scores_scatter.wdl WDL pipeline to calculate all scores with ancestry adjustment
##   - Based on Stephanie Gogarten's Cromwell/WDL scripts with modifications to run on HPC Linux cluster (Slurm)
##
##  Arguments:
##   - Pipeline repo location
##   - Slurm config file
##   - WDL config file for calc_scores_scatter.wdl
##   - TMPDIR: temp space used by Java (required if submitting to interactive node)
##
##  Example Usage (update & submit each line in a Linux xterm):
##  PIPEDIR=/full/path/to/pgsc_calc_wdl_repo    ## Repo is cloned here
##  SLURMCFG=/full/path/to/updated/slurm/config_file
##  WDLCFG=/full/path/to/updated/WDL/config_file
##  TMPDIR=/tmp/${USER}/$$  ## Available temp space on your system
##  mkdir -p ${TMPDIR}
##  today=$(date +%Y%m%d)
##  EMAIL=<<user e-mail>>
##
##   1) interactive node - this will launch jobs to Slurm grid:
##   /bin/bash calc_scores.sh ${PIPEDIR} ${SLURMCFG} ${WDLCFG} ${TMPDIR} 
##
##   2) direct submission to grid (TMPDIR argument is not required)
##   sbatch --mail-user=${EMAIL} --mail-type=FAIL calc_scores.sh ${PIPEDIR} ${SLURMCFG} ${WDLCFG} 
################################
if [ $# -lt 3 ]; then
    echo "Usage: calc_scores.sh <<PIPEDIR>> <<SLURM_CONFIG>> <<calc_scores_WDL_CONFIG>> <<TMPDIR>>"
    exit
else
    echo "Usage: calc_scores.sh $@";
    PIPEDIR=$1
    SLURMCFG=$2
    WDLCFG=$3
fi

if [ $# == 4 ]; then 
    ##  TMPDIR is required if submitting interactively
    TMPDIR=$4
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


##  Load tools 
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

##  Run pipeline
if [ -z "$SLURM_JOB_ID" ];  then
    echo "Submitting calc_scores_scatter.wdl on interactive node"

    # Create tmpdir if not existing
    : "${TMPDIR:=/tmp/${USER}/$$}"
    
    if [ ! -d "${TMPDIR}" ]; then
	mkdir -p ${TMPDIR}
    fi

    # Set trap to clean up on exit
    trap "rm -rf ${TMPDIR}" EXIT
    
    nohup java -Dconfig.file=${SLURMCFG} -Djava.io.tmpdir=${TMPDIR} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/pipe/calc_scores_scatter.wdl --inputs ${WDLCFG} > calc_scores.${today}.log 2>&1 &

else
    echo "Running under Slurm (job ID: $SLURM_JOB_ID)"
    
    java -Dconfig.file=${SLURMCFG} -jar  ${cromwellpath}/cromwell-83.jar run ${PIPEDIR}/pipe/calc_scores_scatter.wdl --inputs ${WDLCFG}

fi





