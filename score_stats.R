library(tidyverse)

compute_overlap <- function(score_vars, overlap_vars) {
    names(score_vars)[1] <- 'ID'
    pgs <- names(score_vars)[str_detect(names(score_vars), '^PGS')]
    overlap <- list()
    for (p in pgs) {
        vars <- select(score_vars, ID, weight=!!p)
        vars <- filter(vars, weight != 0)
        ov <- sum(is.element(vars[['ID']], overlap_vars))/nrow(vars)
        overlap[[p]] <- tibble(score=p, n_variants=nrow(vars), overlap=ov)
    }
    bind_rows(overlap)
}

weighted_sum <- function(score_vars) {
    names(score_vars)[1] <- 'ID'
    pgs <- names(score_vars)[str_detect(names(score_vars), '^PGS')]
    wtsum <- list()
    for (p in pgs) {
        vars <- select(score_vars, ID, weight=!!p)
        vars <- filter(vars, weight != 0)
        wt <- sum(abs(vars$weight))
        wtsum[[p]] <- tibble(score=p, n_variants=nrow(vars), sum_abs_weights=wt)
    }
    bind_rows(wtsum)
}
