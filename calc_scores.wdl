version 1.0

workflow calc_scores {
    input {
        File scorefile
        File pgen
        File pvar
        File psam
        Boolean harmonize_scorefile = false
        Boolean remove_pvar_chr_prefix = false
    }

    if (harmonize_scorefile) {
        call harmonize_score_file {
            input:
                scorefile = scorefile
        }
    }

    if (remove_pvar_chr_prefix) {
        call remove_chr_prefix {
            input:
                pvar = pvar
        }
    }

    call n_cols {
        input:
            file = select_first([harmonize_score_file.scorefile_harmonized, scorefile])
    }

    call plink_score {
        input:
            scorefile = select_first([harmonize_score_file.scorefile_harmonized, scorefile]),
            scorefile_ncols = n_cols.ncols,
            pgen = pgen,
            pvar = select_first([remove_chr_prefix.pvar_nochr, pvar]),
            psam = psam
    }

    output {
        File scores = plink_score.scores
        File variants = plink_score.variants
    }
}


task harmonize_score_file {
    input {
        File scorefile
    }

    command <<<
        set -e -o pipefail
        zcat ~{scorefile} | awk '{$1="chr"$1; print $0}' OFS="\t" | \
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
        }' OFS="\t" > ~{scorefile}_harmonized
    >>>

    output {
        File scorefile_harmonized = "~{scorefile}_harmonized"
    }

    runtime {
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk 10 SSD"
        memory: "16G"
    }
}


task remove_chr_prefix {
    input {
        File pvar
    }

    String outfile = '~{basename(pvar, ".pvar")}_nochr.pvar'

    command <<<
        sed 's/chr//' ~{pvar} > ~{outfile}
    >>>

    output {
        File pvar_nochr = '~{outfile}'
    }

    runtime {
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk 10 SSD"
        memory: "16G"
    }
}


task n_cols {
    input {
        File file
    }

    command <<<
        Rscript -e "dat <- readr::read_tsv('~{file}', n_max=10); writeLines(as.character(ncol(dat)), 'ncols.txt')"
    >>>

    output {
        Int ncols = read_int('ncols.txt')
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
    }

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
        docker: "uwgac/pgsc_calc:0.1.0"
        disks: "local-disk 10 SSD"
        memory: "16G"
        cpu: 2
    }
}
