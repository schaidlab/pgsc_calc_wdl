version 1.0

workflow adjust_scores_empirical {
    input {
        File scores
        File groups
    }

    call adjust_prs_empirical {
        input:
            scores = scores,
            groups = groups
    }

    output {
        File adjusted_scores = adjust_prs_empirical.adjusted_scores
    }
}


task adjust_prs_empirical {
    input {
        File scores
        File groups
        Int mem_gb = 16
    }

    Int disk_size = ceil(2.5*(size(scores, "GB") + size(groups, "GB"))) + 10

    command <<<
        Rscript -e "
        library(readr); \
        source('https://raw.githubusercontent.com/UW-GAC/pgsc_calc_wdl/refs/heads/ancestry_adjust/ancestry_adjustment.R'); \
        scores <- read_tsv('~{scores}'); \
        groups <- read_tsv('~{groups}'); \
        scores <- prep_scores(scores); \
        groups <- prep_groups(groups); \
        adjusted_scores <- adjust_prs_empirical(scores, groups); \
        write_tsv(adjusted_scores, 'adjusted_scores.txt'); \
        "
    >>>

    output {
        File adjusted_scores = "adjusted_scores.txt"
    }

    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
    }
}
