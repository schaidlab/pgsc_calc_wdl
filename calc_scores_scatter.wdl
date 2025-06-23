version 1.0

import "fit_ancestry_model.wdl" as fit_ancestry_model
import "adjust_scores.wdl" as adjust_scores
import "subset_score_file.wdl" as subset

workflow calc_scores_scatter {
    input {
        Array[File] scorefile
        File pgen
        File pvar
        File psam
        Boolean harmonize_scorefile = true
        Boolean add_chr_prefix = false
        Boolean ancestry_adjust = true
        File? pcs
        #File? mean_coef
        #File? var_coef
        File? subset_variants
        String PLINK2
        String RSCRIPT
        File adjust_script
        File aggregate_script
    }

    scatter (sfile in scorefile) {
    
        if (harmonize_scorefile) {
            call harmonize_score_file {
                input:
                    scorefile = sfile
            }
        }

        if (add_chr_prefix) {
            call chr_prefix {
                input:
                    file = select_first([harmonize_score_file.scorefile_harmonized, sfile])
            }
        }

        if (defined(subset_variants)) {
            call subset.subset_scorefile {
                input:
                    scorefile = select_first([chr_prefix.outfile, harmonize_score_file.scorefile_harmonized, sfile]),
                    variants = select_first([subset_variants, ""])
            }
        }

        File scorefile_final = select_first([subset_scorefile.scorefile_subset, chr_prefix.outfile, harmonize_score_file.scorefile_harmonized, sfile])

        call n_cols {
            input:
                file = scorefile_final,
                RSCRIPT = RSCRIPT
        }

 
        call plink_score {
            input:
                scorefile = scorefile_final,
                scorefile_ncols = n_cols.ncols,
                pgen = pgen,
                pvar = pvar,
                psam = psam,
                PLINK2 = PLINK2
        }

        call compute_overlap {
            input:
                scorefile = select_first([chr_prefix.outfile, harmonize_score_file.scorefile_harmonized, scorefile_final]),
                variants = plink_score.variants,
                RSCRIPT = RSCRIPT
        }

        if (ancestry_adjust) {
            call fit_ancestry_model.fit_ancestry_model {
                input:
                    scores = plink_score.scores,
                    pcs = select_first([pcs, ""]),
                    RSCRIPT = RSCRIPT,
                    adjust_script = adjust_script
            }

            call adjust_scores.adjust_scores {
                input:
                    scores = plink_score.scores,
                    pcs = select_first([pcs, ""]),
                    mean_coef = fit_ancestry_model.mean_coef,
                    var_coef = fit_ancestry_model.var_coef,
		    RSCRIPT = RSCRIPT,
		    adjust_script = adjust_script
            }
        }

        File score = plink_score.scores
        File? adjusted_score = adjust_scores.adjusted_scores
        File overlap = compute_overlap.overlap

    }

    Array[File] scores = plink_score.scores
    Array[File?] maybe_adjusted_scores = adjust_scores.adjusted_scores
    Array[File] overlaps = compute_overlap.overlap

    # Remove null entries before aggregating
    Array[File] adjusted_scores = select_all(maybe_adjusted_scores)

    if (defined(adjusted_scores)) {
        call aggregate_results {
            input:
                raw_scores = scores,
	        adjusted_scores = adjusted_scores,
	        overlap_files = overlaps,
	        RSCRIPT = RSCRIPT,
	        aggregate_script = aggregate_script
         }
    }
     
    output {
        File? aggregate_scores = select_first([aggregate_results.aggregate_raw, scores])
        File? aggregate_adjusted_scores = aggregate_results.aggregate_adjusted
        File? score_overlap = select_first([aggregate_results.aggregate_overlap, overlaps])
    }
}


task harmonize_score_file {
    input {
        File scorefile
    }

    #Int disk_size = ceil(5*(size(scorefile, "GB"))) + 10
    String filename = basename(scorefile, ".gz")

    command <<<
        set -e -o pipefail
        zcat ~{scorefile} | \
        awk '{
            if (FNR==1) { print $0; next}
            split($1, a, ":")
            comp['A']='T'; comp['T']='A'; comp['C']='G'; comp['G']='C'
            if (a[4] != $2 && a[4] != comp[$2]) {
                for (i=3; i<=NF; i++) {
                    $i=$i*-1
                }
            }
            $2=a[4]
            print $0
        }' OFS="\t" > ~{filename}_harmonized
        gzip ~{filename}_harmonized
    >>>

    output {
        File scorefile_harmonized = "~{filename}_harmonized.gz"
    }

    runtime {
        #docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "16 GB"
    }
}


task chr_prefix {
    input {
        File file
    }

    #Int disk_size = ceil(5*(size(file, "GB"))) + 10
    String filename = basename(file, ".gz")

    command <<<
        set -e -o pipefail
        zcat ~{file} | awk '{$1="chr"$1; print $0}' OFS="\t" > ~{filename}_chrprefix
        gzip ~{filename}_chrprefix
    >>>

    output {
        File outfile = "~{filename}_chrprefix.gz"
    }

    runtime {
        #docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "16 GB"
    }
}


task n_cols {
    input {
        File file
        String RSCRIPT
    }

    #Int disk_size = ceil(1.5*(size(file, "GB"))) + 5

    command <<<
        ~{RSCRIPT} -e "dat <- readr::read_tsv('~{file}', n_max=10); writeLines(as.character(ncol(dat)), 'ncols.txt')"
    >>>

    output {
        Int ncols = read_int('ncols.txt')
    }

    runtime {
        #docker: "rocker/tidyverse:4"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "16 GB"
    }
}


task plink_score {
    input {
        File scorefile
        Int scorefile_ncols
        File pgen
        File pvar
        File psam
        String prefix = "out"
        Int mem_gb = 16
        Int cpu = 2
        String PLINK2
    }
    
    #Int disk_size = ceil(1.5*(size(pgen, "GB") + size(pvar, "GB") + size(psam, "GB") + size(scorefile, "GB"))) + 10

    command <<<
        ~{PLINK2} --pgen ~{pgen} --pvar ~{pvar} --psam ~{psam} --score ~{scorefile} \
            no-mean-imputation header-read list-variants cols=+scoresums \
            --memory 10000 \
            --score-col-nums 3-~{scorefile_ncols} \
            --out ~{prefix}
    >>>

    output {
        File scores = "~{prefix}.sscore"
        File variants = "~{prefix}.sscore.vars"
    }

    runtime {
        #docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
        cpu: "~{cpu}"
    }
}


task compute_overlap {
    input {
        File scorefile
        File variants
        Int mem_gb = 64
        String RSCRIPT
    }

    #Int disk_size = ceil(3*(size(scorefile, "GB") + size(variants, "GB"))) + 10

    command <<<
        ~{RSCRIPT} -e " \
        library(tidyverse); \
        score_vars <- read_tsv('~{scorefile}'); \
        overlap_vars <- readLines('~{variants}'); \
        names(score_vars)[1] <- 'ID'; \
        pgs <- names(score_vars)[str_detect(names(score_vars), '^PGS')]; \
        overlap <- list(); \
        for (p in pgs) { \
            vars <- select(score_vars, ID, weight=!!p); \
            vars <- filter(vars, weight != 0); \
            ov <- sum(is.element(vars[['ID']], overlap_vars))/nrow(vars); \
            overlap[[p]] <- tibble(score=p, n_variants=nrow(vars), overlap=ov); \
        }; \
        overlap <- bind_rows(overlap); \
        write_tsv(overlap, 'score_overlap.tsv'); \
        "
    >>>

    output {
        File overlap = "score_overlap.tsv"
    }

    runtime {
        #docker: "rocker/tidyverse:4"
        #disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb} GB"
    }
}


task aggregate_results {
    input {
        Array[File] raw_scores
        Array[File] adjusted_scores
        Array[File] overlap_files
        String RSCRIPT
        File aggregate_script
        String prefix = "all"
        Int mem_gb = 8
     }

    command <<<
        ~{RSCRIPT} ~{aggregate_script} \
            --raw_files "~{sep=',' raw_scores}" \
            --adjusted_files "~{sep=',' adjusted_scores}" \
            --overlap_files "~{sep=',' overlap_files}" \
            --out_prefix ~{prefix}
    >>>

    output {
        File aggregate_raw = "~{prefix}_raw_scores.tsv"
        File aggregate_adjusted = "~{prefix}_adjusted_scores.tsv"
        File aggregate_overlap = "~{prefix}_overlap.tsv"
    }

    runtime {
        memory: "~{mem_gb} GB"
	}
}
