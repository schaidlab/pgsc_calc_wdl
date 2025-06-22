version 1.0

workflow fit_ancestry_model {
    input {
        File scores
        File pcs
        File adjust_script
        String RSCRIPT
        Int mem_gb = 16
    }

    call find_ancestry_coefficients {
        input:
            scores = scores,
            pcs = pcs,
            RSCRIPT = RSCRIPT,
            adjust_script = adjust_script,
            mem_gb = mem_gb
    }

    output {
        File mean_coef = find_ancestry_coefficients.mean_coef
        File var_coef = find_ancestry_coefficients.var_coef
    }
}


task find_ancestry_coefficients {
    input {
        File scores
        File pcs
        Int mem_gb = 16
        String RSCRIPT
        File adjust_script
    }

    #Int disk_size = ceil(2.5*(size(scores, "GB") + size(pcs, "GB"))) + 10

    command <<<
        ~{RSCRIPT} -e "
        library(readr); \
        source('~{adjust_script}'); \
        scores <- read_tsv('~{scores}'); \
        pcs <- read_tsv('~{pcs}'); \
        scores <- prep_scores(scores); \
        model <- fit_prs(scores, pcs); \
        write_tsv(model[['mean_coef']], 'mean_coef.txt'); \
        write_tsv(model[['var_coef']], 'var_coef.txt'); \
        "
    >>>

    output {
        File mean_coef = "mean_coef.txt"
        File var_coef = "var_coef.txt"
    }

    runtime {
        #docker: "rocker/tidyverse:4"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}
