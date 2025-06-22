version 1.0

workflow adjust_scores {
    input {
        File scores
        File pcs
        File mean_coef
        File var_coef
        String RSCRIPT
        File adjust_script
        Int mem_gb = 16
    }

    call adjust_prs {
        input:
            scores = scores,
            pcs = pcs,
            mean_coef = mean_coef,
            var_coef = var_coef,
            RSCRIPT = RSCRIPT,
            adjust_script = adjust_script,
            mem_gb = mem_gb
    }

    output {
        File adjusted_scores = adjust_prs.adjusted_scores
    }
}


task adjust_prs {
    input {
        File scores
        File pcs
        File mean_coef
        File var_coef
        Int mem_gb = 16
        String RSCRIPT
        File adjust_script
    }

    #Int disk_size = ceil(2.5*(size(scores, "GB") + size(pcs, "GB") + size(mean_coef, "GB") + size(var_coef, "GB"))) + 10

    command <<<
        ~{RSCRIPT} -e "
        library(readr); \
        source('~{adjust_script}'); \
        scores <- read_tsv('~{scores}'); \
        pcs <- read_tsv('~{pcs}'); \
        mean_coef <- read_tsv('~{mean_coef}'); \
        var_coef <- read_tsv('~{var_coef}'); \
        scores <- prep_scores(scores); \
        adjusted_scores <- adjust_prs(scores, pcs, mean_coef, var_coef); \
        write_tsv(adjusted_scores, 'adjusted_scores.txt'); \
        "
    >>>

    output {
        File adjusted_scores = "adjusted_scores.txt"
    }

    runtime {
        #docker: "rocker/tidyverse:4"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}
