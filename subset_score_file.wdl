version 1.0

workflow subset_score_file {
    input {
        File scorefile
        File variants
        String RSCRIPT
        Int mem_gb = 64
    }

    call subset_scorefile {
        input:
            scorefile = scorefile,
            variants = variants,
            RSCRIPT = RSCRIPT,
            mem_gb = mem_gb
    }

    output {
        File scorefile_subset = subset_scorefile.scorefile_subset
    }
    
}


task subset_scorefile {
    input {
        File scorefile
        File variants
        Int mem_gb = 64
        String RSCRIPT
    }

    #Int disk_size = ceil(5*(size(scorefile, "GB") + size(variants, "GB"))) + 10
    String filename = basename(scorefile, ".gz")

    command <<<
        ~{RSCRIPT} -e " \
        library(tidyverse); \
        score_vars <- read_tsv('~{scorefile}'); \
        overlap_vars <- readLines('~{variants}'); \
        names(score_vars)[1] <- 'ID'; \
        score_vars <- filter(score_vars, is.element(ID, overlap_vars)); \
        write_tsv(score_vars, '~{filename}_subset.gz'); \
        "
    >>>

    output {
        File scorefile_subset = "~{filename}_subset.gz"
    }

    runtime {
        #docker: "rocker/tidyverse:4"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}
