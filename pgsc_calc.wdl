version 1.0

workflow pgsc_calc {
    input {
        Array[File] vcf_file
        Array[String] chromosome
        String sampleset = "cohort"
    }

    call pgsc_calc_nextflow {
        input:
            vcf_file = vcf_file,
            chromosome = chromosome,
            sampleset = sampleset
    }

    output {
        
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}

task pgsc_calc_nextflow {
    input {
        Array[File] vcf_file
        Array[String] chromosome
        String sampleset
        Int mem_gb = 16
        Int cpu = 2
    }

    command <<<
        set -e -o pipefail

        Rscript -e "\
        files <- readLines('~{write_lines(vcf_file)}'); \
        chrs <- readLines('~{write_lines(chromosome)}'); \
        stopifnot(length(files) == length(chrs))
        sampleset <- tibble::tibble(sampleset = '~{sampleset}', path_prefix=files, chrom=chrs, format='vcf'); \
        readr::write_csv(sampleset, 'sampleset.csv'); \
        "

        #nextflow run pgscatalog/pgsc_calc -r v2.0.0-alpha.5 -profile test,conda
    >>>

    output {
        File sampleset = "sampleset.csv"
    }

    runtime {
        docker: "uwgac/pgsc_calc:0.1.0"
        memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}
