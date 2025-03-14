version 1.0

workflow calc_scores {
    input {
        File scorefile
        File pgen
        File pvar
        File psam
        Boolean harmonize_scorefile = true
        Boolean add_chr_prefix = true
    }

    if (harmonize_scorefile) {
        call harmonize_score_file {
            input:
                scorefile = scorefile
        }
    }

    if (add_chr_prefix) {
        call chr_prefix {
            input:
                file = select_first([harmonize_score_file.scorefile_harmonized, scorefile])
        }
    }

    File scorefile_final = select_first([chr_prefix.outfile, harmonize_score_file.scorefile_harmonized, scorefile])

    call n_cols {
        input:
            file = scorefile_final
    }

    call plink_score {
        input:
            scorefile = scorefile_final,
            scorefile_ncols = n_cols.ncols,
            pgen = pgen,
            pvar = pvar,
            psam = psam
    }

    call compute_overlap {
        input:
            scorefile = scorefile_final,
            variants = plink_score.variants
    }

    output {
        File scores = plink_score.scores
        File variants = plink_score.variants
        File overlap = compute_overlap.overlap
    }
}


task harmonize_score_file {
    input {
        File scorefile
    }

    Int disk_size = ceil(5*(size(scorefile, "GB"))) + 10
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
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk ~{disk_size} SSD"
        memory: "16G"
    }
}


task chr_prefix {
    input {
        File file
    }

    Int disk_size = ceil(5*(size(file, "GB"))) + 10
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
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk ~{disk_size} SSD"
        memory: "16G"
    }
}


task n_cols {
    input {
        File file
    }

    Int disk_size = ceil(1.5*(size(file, "GB"))) + 5

    command <<<
        Rscript -e "dat <- readr::read_tsv('~{file}', n_max=10); writeLines(as.character(ncol(dat)), 'ncols.txt')"
    >>>

    output {
        Int ncols = read_int('ncols.txt')
    }

    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "16G"
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
    }
    
    Int disk_size = ceil(1.5*(size(pgen, "GB") + size(pvar, "GB") + size(psam, "GB") + size(scorefile, "GB"))) + 10

    command <<<
        plink2 --pgen ~{pgen} --pvar ~{pvar} --psam ~{psam} --score ~{scorefile} \
            no-mean-imputation header-read list-variants cols=+scoresums --score-col-nums 3-~{scorefile_ncols} \
            --out ~{prefix}
    >>>

    output {
        File scores = "~{prefix}.sscore"
        File variants = "~{prefix}.sscore.vars"
    }

    runtime {
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}


task compute_overlap {
    input {
        File scorefile
        File variants
        Int mem_gb = 32
    }

    Int disk_size = ceil(3*(size(scorefile, "GB") + size(variants, "GB"))) + 10

    command <<<
        Rscript -e " \
        library(tidyverse); \
        score_vars <- read_tsv('~{scorefile}'); \
        overlap_vars <- readLines('~{variants}'); \
        pgs <- names(score_vars)[str_detect(names(score_vars), '^PGS')]; \
        overlap <- list(); \
        for (p in pgs) { \
            vars <- select(score_vars, ID, weight=!!p); \
            vars <- filter(vars, weight != 0); \
            ov <- sum(is.element(vars[['ID']], overlap_vars))/nrow(vars); \
            overlap[[p]] <- tibble(score=p, overlap=ov); \
        }; \
        overlap <- bind_rows(overlap); \
        write_tsv(overlap, 'score_overlap.tsv'); \
        "
    >>>

    output {
        File overlap = "score_overlap.tsv"
    }

    runtime {
        docker: "rocker/tidyverse:4"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
    }
}
