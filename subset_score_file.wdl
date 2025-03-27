version 1.0

workflow subset_score_file {
    input {
        File scorefile
        File variants
    }

    call subset_scorefile {
        input:
            scorefile = scorefile,
            variants = variants
    }

    output {
        File scorefile_subset = subset_scorefile.scorefile_subset
    }
    
}


task subset_scorefile {
    input {
        File scorefile
        File variants
        Int mem_gb = 16
    }

    Int disk_size = ceil(5*(size(scorefile, "GB") + size(variants, "GB"))) + 10
    String filename = basename(scorefile, ".gz")

    command <<<
        set -e -o pipefail
        zcat ~{scorefile} | head -n 1 > header.txt
        head header.txt
        zcat ~{scorefile} | awk 'FNR==NR{a[$1]; next}{if($1 in a){print $0}}' ~{variants} ~{scorefile} > tmp.txt
        head tmp.txt
        rm ~{scorefile}
        cat header.txt tmp.txt > ~{filename}_subset
        head ~{filename}_subset
        gzip ~{filename}_subset
        ls
    >>>

    output {
        File scorefile_subset = "~{filename}_subset.gz"
    }

    runtime {
        docker: "quay.io/biocontainers/plink2:2.00a5.12--h4ac6f70_0"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
    }
}
