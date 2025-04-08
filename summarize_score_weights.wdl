version 1.0

workflow summarize_score_weights {
    input {
        File scorefile
        File? variants
    }

    if (defined(variants)) {
        call score_weight_abs_sum_overlap {
            input:
                scorefile = scorefile,
                variants = select_first([variants, ""])
        }
    }
    if (!defined(variants)) {
        call score_weight_abs_sum_all {
            input:
                scorefile = scorefile
        }
    }

    output {
        File scorefile_weights = select_first([score_weight_abs_sum_overlap.score_weights, score_weight_abs_sum_all.score_weights])
    }
}


task score_weight_abs_sum_all {
    input {
        File scorefile
    }

    command <<<
        Rscript -e " \
        library(readr); \
        source('https://raw.githubusercontent.com/UW-GAC/pgsc_calc_wdl/refs/heads/ancestry_adjust/score_stats.R'); \
        score_vars <- read_tsv('~{scorefile}'); \
        score_wts <- weighted_sum(score_vars); \
        write_tsv(score_wts, 'score_weights.txt'); \
        "
    >>>

    output {
        File score_weights = "score_weights.txt"
    }
}


task score_weight_abs_sum_overlap {
    input {
        File scorefile
        File variants
    }

    command <<<
        Rscript -e " \
        library(readr); \
        source('https://raw.githubusercontent.com/UW-GAC/pgsc_calc_wdl/refs/heads/ancestry_adjust/score_stats.R'); \
        score_vars <- read_tsv('~{scorefile}'); \
        overlap_vars <- readLines('~{variants}'); \
        score_wts <- weighted_sum(score_vars, overlap_vars); \
        write_tsv(score_wts, 'score_weights.txt'); \
        "
    >>>

    output {
        File score_weights = "score_weights.txt"
    }
}