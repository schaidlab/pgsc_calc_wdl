# pgsc_calc_wdl
WDL wrapper for the [pgsc_calc](https://pgsc-calc.readthedocs.io/en/latest/) workflow

The first step of the workflow [formats the input genomes](https://pgsc-calc.readthedocs.io/en/latest/how-to/prepare.html) in PLINK2 format.

The next step [runs the pgsc_calc nextflow workflow](https://pgsc-calc.readthedocs.io/en/latest/getting-started.html) inside a docker container. 

input | description
--- | ---
vcf | Array of VCF files
chromosome | Array of chromosome strings (1-22, X, Y) corresponding to `vcf`. If there is one VCF file with multiple chromosomes, this input should be an empty string (`[""]`)
target_build | "GRCh38" (default) or "GRCh37"
pgs_id | PGS catalog IDs to calculate (e.g. `["PGS001229", "PGS000802"]`)
run_ancestry | `true` to [perform ancestry adjustment](https://pgsc-calc.readthedocs.io/en/latest/explanation/geneticancestry.html) using a reference panel, `false` to skip this step
ref_panel | Google bucket path of a reference panel file (e.g. `gs://fc-a8511200-791a-4375-bccf-fbe41ac3f9f6/pgsc_HGDP+1kGP_v1.tar.zst`); used if `run_ancestry` is `true`
sampleset_name | Name of the sampleset; used to construct output file names (default "cohort")
arguments | [Additional arguments](https://pgsc-calc.readthedocs.io/en/latest/reference/params.html#param-ref) to pass to psgc_calc

Output files from pgsc_calc are described [here](https://pgsc-calc.readthedocs.io/en/latest/explanation/output.html#interpret).
