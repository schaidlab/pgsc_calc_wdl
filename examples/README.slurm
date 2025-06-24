************************************************************************* 
**   STUDY TITLE: PRIMED legacy project: PRSMix
**      UNIX DIR:  /research/staging/emerge-bsi/scripts/README
** 
** Creation Date : Tuesday, 17 June 2025 07:52 AM CDT
** Last Modified : Tuesday, 17 June 2025 07:52 AM CDT
************************************************************************* 
 
PRS Calculation for PRIMED PRSMix using WDL/cromwell pipeline calc_scores.wdl

PRIMED CC developed an alternate (to pgsc_calc) workflow which runs PLINK directly on the scorefiles
available in the PRIMED_LEGACY workspace. We modified that workflow to run on a high performance computing environment running Slurm.


************
** Steps required to run PGS WDL scripts on Slurm HPC 
************

0. Download harmonized score files

1. Clone git repo [SchaidLab repo](https://github.com/schaidlab/pgsc_calc_wdl)

2. Create a slurm.conf configuration file specifying your local Slurm parameterization
   -- See **slurm.example.conf** file as an example
   -- User will need to modify:
      a. root (where cromwell will run)
      b. Queue name (line 12)
      c. You may need to update --time depending your queue maxtime (sinfo will show partitions available on your system). (line 23)
      d. Confirm slurm mail-type used by your institution (line 24)
      e. User e-mail (line 25)
      
      
3. Run womtool to generate base config files for the 2 pipelines. Note, you must be in the repo directory when you submit the womtool command in order to correctly find all task scripts. For example: 

   PIPEDIR=/path/to/cloned/repo/pgsc_calc_wdl   # Path to cloned repo
   CFGDIR=/path/to/my/project/config            # Path to write resulting json file
   # load tools into your local environment    
   module load java	   
   module load cromwell/83
   cromwell=<<path/to/cromwell/83>>
   # Use womtool to generate json shell to run pgsc_calc_prepare_genomes.wdl
   java -jar -Djava.io.tmpdir=/tmp/${USER}/$$ ${cromwell}/womtool-83.jar inputs ${PIPEDIR}/pgsc_calc_prepare_genomes.wdl > ${CFG}/pgsc_calc_prepare_genomes.raw.json

   # Use womtool to generate json shell to run calc_scores.wdl
   java -jar -Djava.io.tmpdir=/tmp/${USER}/$$ ${cromwell}/womtool-83.jar inputs ${PIPEDIR}/calc_scores.wdl > ${CFG}/calc_scores.raw.json


4. Prepare genotype data:  Update JSON files for each wdl script
   a. See example *json files in repo: calc_scores_scatter.template.json and pgsc_calc_prepare_genomes.template.json
   b. Update raw JSON to reflect all data & tool paths on your system.
      	1) "Array[File]" input should use this format: 

    	"pgsc_calc_prepare_genomes.vcf" : [
            "/full/path/to/by-chrom/VCF/files.chr1.vcf.gz",
	    ...
	    "/full/path/to/by-chrom/VCF/files.chr22.vcf.gz"	
        ],

	2) Update path to PLINK2 and Rscript on your system

   	3) Note, pgen/psam/pvar inputs for calc_scores.wdl depend on completion of the first step (pgsc_calc_prepare_genomes): e.g., 
    	"calc_scores.pgen": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.pgen",
    	"calc_scores.psam": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.psam",
    	"calc_scores.pvar": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.pvar",

   c. After updating the JSON file, submit the pipeline (assumes you have named your JSON  ${CFGDIR}/pgsc_calc_prepare_genomes.json)
   
   Linux command: 
   > today=`date +%d%b%Y`
   > nohup java -Dconfig.file=${CFGDIR}/slurm.conf -Djava.io.tmpdir=${TMPDIR} -jar ${cromwell}/cromwell-83.jar run ${PIPEDIR}/pgsc_calc_prepare_genomes.wdl --inputs ${CFGDIR}/pgsc_calc_prepare_genomes.json > prep_genome.${today}.log 2>&1 &

 

5. Run wdl (with custom backend) to calculate scores and apply ancestry adjustment: calc_scores_scatter.wdl
   a. See example *json files in repo: calc_scores_scatter.template.json
   b. Update raw JSON to reflect all data & tool paths on your system.
      	1) "Array[File]" input should use this format: 

	"calc_scores_scatter.pgsc_calc_prepare_genomes.vcf" : [
            "/full/path/to/pgscat_weight_00_allchr_additive_0.scorefile.gz",
    	    ...
	    "/full/path/to/pgscat_weight_10_allchr_additive_0.scorefile.gz"
        ],

	2) Update paths to full-genome PGEN files (result of running pgsc_calc_prepare_genomes.wdl)
	    Note, pgen/psam/pvar inputs for calc_scores_scatter.wdl depend on completion of the first step (pgsc_calc_prepare_genomes): e.g., 
	    "calc_scores_scatter.pgen": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.pgen",
    	    "calc_scores_scatter.psam": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.psam",
    	    "calc_scores_scatter.pvar": "/full/path/to/project/cromwell-executions/pgsc_calc_prepare_genomes/668d4478-5152-44db-a59e-2bab513b38de/call-merge_files/execution/merged.pvar",

	3) Update path to projection PCs for your samples

	4) Update paths to PLINK2 and Rscript on your system

	5) Update paths to R scripts in downloaded repo
	    "calc_scores_scatter.adjust_script": "/path/to/repo/pgsc_calc_wdl/ancestry_adjustment.R",
	    "calc_scores_scatter.aggregate_script": "/path/to/repo/pgsc_calc_wdl/aggregate_scores.R",

    c. After updating the JSON file, submit the pipeline (assumes you have named your JSON  ${CFGDIR}/calc_scores_scatter.json)
	   
   Linux command: 
   > today=`date +%d%b%Y`
   > nohup java -Dconfig.file=${CFGDIR}/slurm.conf -Djava.io.tmpdir=${TMPDIR} -jar ${cromwell}/cromwell-83.jar run ${PIPEDIR}/calc_scores_scatter.wdl --inputs ${CFGDIR}/calc_scores_scatter.json > calc_scores.${today}.log 2>&1 &

   

