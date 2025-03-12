# pgsc_calc_wdl

## pgsc_calc

WDL wrapper for the [pgsc_calc](https://pgsc-calc.readthedocs.io/en/latest/) workflow

The first step of the workflow [formats the input genomes](https://pgsc-calc.readthedocs.io/en/latest/how-to/prepare.html) in PLINK2 format.

The next step [runs the pgsc_calc nextflow workflow](https://pgsc-calc.readthedocs.io/en/latest/getting-started.html) inside a docker container. 

input | description
--- | ---
vcf | Array of VCF files. If provided, will be converted to pgen/pvar/psam. If not provided, use pgen/pvar/psam inputs instead.
pgen | Array of pgen files
pvar | Array of pvar files
psam | Array of psam files
chromosome | Array of chromosome strings (1-22, X, Y) corresponding to `vcf` or `pgen/pvar/psam`. If there is one file with multiple chromosomes, this input should be an empty string (`[""]`)
target_build | `"GRCh38"` (default) or `"GRCh37"`
pgs_id | PGS catalog IDs to calculate (e.g. `"PGS001229, PGS000802"`)
scorefile | Score file in the [required format](https://pgsc-calc.readthedocs.io/en/latest/how-to/calculate_custom.html).
ancestry_ref_panel | Google bucket path of a reference panel file (e.g. `"gs://fc-a8511200-791a-4375-bccf-fbe41ac3f9f6/pgsc_HGDP+1kGP_v1.tar.zst"`) to [perform ancestry adjustment](https://pgsc-calc.readthedocs.io/en/latest/explanation/geneticancestry.html). If not provided, no ancestry adjustment is performed.
sampleset_name | Name of the sampleset; used to construct output file names (default `"cohort"`)
arguments | [Additional arguments](https://pgsc-calc.readthedocs.io/en/latest/reference/params.html#param-ref) to pass to psgc_calc

Output files from pgsc_calc are described [here](https://pgsc-calc.readthedocs.io/en/latest/explanation/output.html#interpret).


## pgsc_calc_prepare_genomes

Standalone workflow to convert VCF to pgen/pvar/psam.

input | description
--- | ---
vcf | Array of VCF files
merge_chroms | Boolean for whether to merge files to a single set of output files with all chromosomes
snps_only | Boolean for whether to keep only SNPs in output

output description
--- | ---
pgen | Array of pgen files
pvar | Array of pvar files
psam | Array of psam files


## calc_scores

Calculate scores without using Nextflow. Use pgsc_calc_prepare_genomes first to generate files.

input | description
--- | ---
scorefile | score file
pgen | pgen file
pvar | pvar file
psam | psam file
harmonize_scorefile | Boolean for whether to harmonize scorefile to consistent effect allele (default true)
add_chr_prefix | Boolean for whether to add "chr" prefix to scorefile variant ids to match pvar (default true)
