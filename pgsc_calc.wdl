version 1.0

import "pgsc_calc_prepare_genomes.wdl" as prep

workflow pgsc_calc {
    input {
        Array[File]? vcf
        Array[File]? pgen
        Array[File]? pvar
        Array[File]? psam
        Array[String] chromosome
        String target_build = "GRCh38"
        Array[String]? pgs_id
        Array[File] scorefile = [""]
        File? ancestry_ref_panel
        String sampleset_name = "cohort"
        Array[String]? arguments
    }

    if (defined(vcf)) {
        scatter (file in select_first([vcf, ""])) {
            call prep.prepare_genomes {
                input:
                    vcf = file
            }
        }
    }

    scatter (sf in scorefile) {
        call pgsc_calc_nextflow {
            input:
                pgen = select_first([prepare_genomes.pgen, pgen]),
                pvar = select_first([prepare_genomes.pvar, pvar]),
                psam = select_first([prepare_genomes.psam, psam]),
                chromosome = chromosome,
                pgs_id = pgs_id,
                scorefile = sf,
                target_build = target_build,
                ancestry_ref_panel = ancestry_ref_panel,
                sampleset = sampleset_name,
                arguments = arguments
        }
    }

    output {
        Array[File] match_files = flatten(pgsc_calc_nextflow.match_files)
        Array[File] score_files = flatten(pgsc_calc_nextflow.score_files)
        Array[File] log_files = flatten(pgsc_calc_nextflow.log_files)
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task pgsc_calc_nextflow {
    input {
        Array[File] pgen
        Array[File] pvar
        Array[File] psam
        Array[String] chromosome
        String target_build
        Array[String]? pgs_id
        File? scorefile
        File? ancestry_ref_panel
        String sampleset
        Array[String]? arguments
        Int disk_gb = 128
        Int mem_gb = 64
        Int cpu = 16
    }

    String pgs_arg = if (defined(pgs_id)) then "--pgs_id ~{sep=',' pgs_id}" else "--scorefile " + scorefile

    command <<<
        set -e -o pipefail

        Rscript -e "\
        files <- readLines('~{write_lines(pgen)}'); \
        chrs <- readLines('~{write_lines(chromosome)}'); \
        stopifnot(length(files) == length(chrs)); \
        file_prefix <- sub('.pgen$', '', files); \
        sampleset <- tibble::tibble(sampleset = '~{sampleset}', path_prefix=file_prefix, chrom=chrs, format='pfile'); \
        readr::write_csv(sampleset, 'samplesheet.csv'); \
        "

        nextflow run pgscatalog/pgsc_calc -r v2.0.0-alpha.5 -profile conda \
            --input samplesheet.csv \
            --target_build ~{target_build} \
            ~{pgs_arg} \
            ~{"--run_ancestry " + ancestry_ref_panel} \
            ~{sep=" " arguments}
    >>>

    output {
        File samplesheet = "samplesheet.csv"
        Array[File] match_files = glob("results/~{sampleset}/match/*")
        Array[File] score_files = glob("results/~{sampleset}/score/*")
        Array[File] log_files = glob("results/pipeline_info/*")
    }

    runtime {
        #docker: "uwgac/pgsc_calc:0.1.0"
        docker: "us-docker.pkg.dev/primed-cc/pgsc-calc/pgsc_calc:0.1.0"
        disks: "local-disk ~{disk_gb} SSD"
        memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}
