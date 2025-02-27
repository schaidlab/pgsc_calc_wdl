version 1.0

workflow pgsc_calc_prepare_genomes {
    input {
        Array[File] vcf
    }

    scatter (file in vcf) {
        call prepare_genomes {
            input:
                vcf = file
        }
    }

    output {
        Array[File] pgen = prepare_genomes.pgen
        Array[File] pvar = prepare_genomes.pvar
        Array[File] psam = prepare_genomes.psam
    }

     meta {
          author: "Stephanie Gogarten"
          email: "sdmorris@uw.edu"
    }
}


task prepare_genomes {
    input {
        File vcf
        Int mem_gb = 16
        Int cpu = 2
    }

    Int disk_size = ceil(2.5*(size(vcf, "GB"))) + 5
    String filename = basename(vcf)
    String basename = sub(filename, "[[:punct:]][bv]cf.*z?$", "")
    String prefix = if (sub(filename, ".bcf", "") != filename) then "--bcf" else "--vcf"

    command <<<
        plink2 ~{prefix} ~{vcf}  \
            --allow-extra-chr \
            --chr 1-22, X, Y, XY \
            --make-pgen --out ~{basename}
    >>>

    output {
        File pgen = "~{basename}.pgen"
        File pvar = "~{basename}.pvar"
        File psam = "~{basename}.psam"
    }

    runtime {
        docker: "uwgac/pgsc_calc:0.1.0"
        #docker: "us-docker.pkg.dev/primed-cc/pgsc-calc/pgsc_calc:0.1.0"
        disks: "local-disk ~{disk_size} SSD"
        memory: "~{mem_gb}G"
        cpu: "~{cpu}"
    }
}
