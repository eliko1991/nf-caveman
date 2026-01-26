process CAVEMAN_ADD_IDS {
    tag "add_ids"
    label 'process_low'

    container 'papaemmelab/docker-cgp:v1.1'

    publishDir "${params.outdir}", mode: params.publish_dir_mode, pattern: "*.snps.ids.vcf.gz*"

    input:
    path(workdir)

    output:
    path("*.muts.ids.vcf.gz"),     emit: vcf
    path("*.muts.ids.vcf.gz.tbi"), emit: vcf_tbi
    path("*.snps.ids.vcf.gz"),     emit: snps_vcf
    path("*.snps.ids.vcf.gz.tbi"), emit: snps_vcf_tbi
    path(workdir),                 emit: workdir

    script:
    """
    caveman.pl \\
        -process add_ids \\
        -index 1 \\
        -threads ${task.cpus} \\
        -logs ${workdir}/clogs \\
        -outdir ${workdir}

    # Compress and index VCFs
    MUTS_VCF=\$(ls ${workdir}/tmpCaveman/*.muts.ids.vcf)
    SNPS_VCF=\$(ls ${workdir}/tmpCaveman/*.snps.ids.vcf)

    bgzip \${MUTS_VCF}
    bgzip \${SNPS_VCF}

    # Get sample names for output naming
    MUTS_BASENAME=\$(basename \${MUTS_VCF})
    SNPS_BASENAME=\$(basename \${SNPS_VCF})

    # Copy to working directory for output
    cp ${workdir}/tmpCaveman/\${MUTS_BASENAME}.gz ./
    cp ${workdir}/tmpCaveman/\${SNPS_BASENAME}.gz ./

    tabix -p vcf \${MUTS_BASENAME}.gz
    tabix -p vcf \${SNPS_BASENAME}.gz
    """
}
