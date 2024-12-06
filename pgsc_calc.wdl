version 1.0

workflow pgsc_calc {
    input {
        Array[File] vcf
        Array[String] chromosome
        String target_build = "GRCh38"
        Array[String] pgs_id
        String sampleset = "cohort"
    }

    scatter (file in vcf) {
        call prepare_genomes {
            input:
                vcf = file
        }
    }

    call pgsc_calc_nextflow {
        input:
            pgen = prepare_genomes.pgen,
            pvar = prepare_genomes.pvar,
            psam = prepare_genomes.psam,
            chromosome = chromosome,
            pgs_id = pgs_id,
            target_build = target_build,
            sampleset = sampleset
    }

    output {
        Array[File] match_files = pgsc_calc_nextflow.match_files
        Array[File] score_files = pgsc_calc_nextflow.score_files
        Array[File] log_files = pgsc_calc_nextflow.log_files
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task prepare_genomes {
    input {
        File vcf
        Int mem_gb = 16
        Int cpu = 2
    }

	Int disk_size = ceil(2.5*(size(vcf, "GB"))) + 5
	String filename = basename(vcf)
	String basename = sub(filename, "[[:punct:]][bv]cf.*z?$", "")
	String prefix = if (sub(filename, ".bcf", "") != filename) then "--bcf" else "--vcf"

    command <<<
        plink2 ~{prefix} ~{vcf}  \
            --allow-extra-chr \
            --chr 1-22, X, Y, XY \
            --make-pgen --out ~{basename}
    >>>

    output {
        File pgen = "~{basename}.pgen"
        File pvar = "~{basename}.pvar"
        File psam = "~{basename}.psam"
    }

    runtime {
        docker: "uwgac/pgsc_calc:0.1.0"
		disks: "local-disk ~{disk_size} SSD"
		memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}


task pgsc_calc_nextflow {
    input {
        Array[File] pgen
        Array[File] pvar
        Array[File] psam
        Array[String] chromosome
        String target_build
        Array[String] pgs_id
        String sampleset
        Int mem_gb = 64
        Int cpu = 16
    }
    
	Int disk_size = ceil(1.5*(size(pgen, "GB") + size(pvar, "GB") + size(psam, "GB"))) + 10

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
            --pgs_id ~{sep="," pgs_id}
    >>>

    output {
        File samplesheet = "samplesheet.csv"
        Array[File] match_files = glob("results/~{sampleset}/match/*")
        Array[File] score_files = glob("results/~{sampleset}/score/*")
        Array[File] log_files = glob("results/pipeline_info/*")
    }

    runtime {
        docker: "uwgac/pgsc_calc:0.1.0"
		disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}
