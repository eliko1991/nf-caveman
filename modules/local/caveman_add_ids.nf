process CAVEMAN_ADD_IDS {
    tag "add_ids"
    label 'process_low'

    //container 'papaemmelab/docker-cgp:v1.1'
    container '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif'

    publishDir "${params.outdir}", mode: params.publish_dir_mode, pattern: "*.snps.ids.vcf.gz*"

    input:
    tuple path(workdir), path(tumour_bam), path(tumour_bai), path(normal_bam), path(normal_bai), path(reference_fai), path(normal_cn), path(tumour_cn), path(ignore_file)

    output:
    path("*.muts.ids.vcf.gz"),     emit: vcf
    path("*.muts.ids.vcf.gz.tbi"), emit: vcf_tbi
    path("*.snps.ids.vcf.gz"),     emit: snps_vcf
    path("*.snps.ids.vcf.gz.tbi"), emit: snps_vcf_tbi
    path(workdir),                 emit: workdir

    script:
    def norm_cn_def       = params.norm_cn_default ? "-norm-cn-default ${params.norm_cn_default}" : ""
    def tum_cn_def        = params.tum_cn_default  ? "-tum-cn-default ${params.tum_cn_default}"   : ""
    def species_arg       = params.species         ? "-species ${params.species}"                 : ""
    def assembly_arg      = params.species_assembly ? "-species-assembly ${params.species_assembly}" : ""
    def seqtype_arg       = params.seqType         ? "-seqType ${params.seqType}"                 : ""
    def normal_prot       = params.normal_protocol ? "-normal-protocol ${params.normal_protocol}" : ""
    def tumour_prot       = params.tumour_protocol ? "-tumour-protocol ${params.tumour_protocol}" : ""
    def contam_arg        = params.normal_contamination ? "-normal-contamination ${params.normal_contamination}" : ""
    """
    # Save original directory for output files
    ORIG_DIR=\$(pwd)

    # Get absolute paths before changing directory
    TUMOUR_BAM_ABS=\$(readlink -f ${tumour_bam})
    NORMAL_BAM_ABS=\$(readlink -f ${normal_bam})
    REF_FAI_ABS=\$(readlink -f ${reference_fai})
    WORKDIR_ABS=\$(readlink -f ${workdir})

    # Handle optional files
    NORMAL_CN_ARG=""
    if [ -f "${normal_cn}" ] && [ "${normal_cn}" != "NO_FILE" ]; then
        NORMAL_CN_ARG="-normal-cn \$(readlink -f ${normal_cn})"
    fi

    TUMOUR_CN_ARG=""
    if [ -f "${tumour_cn}" ] && [ "${tumour_cn}" != "NO_FILE" ]; then
        TUMOUR_CN_ARG="-tumour-cn \$(readlink -f ${tumour_cn})"
    fi

    IGNORE_ARG=""
    if [ -f "${ignore_file}" ] && [ "${ignore_file}" != "NO_FILE" ]; then
        IGNORE_ARG="-ignore-file \$(readlink -f ${ignore_file})"
    fi

    # CaVEMan requires running from the same directory where setup was performed
    SETUP_DIR=\$(dirname \$WORKDIR_ABS)
    cd \$SETUP_DIR

    caveman.pl \\
        -process add_ids \\
        -index 1 \\
        -threads ${task.cpus} \\
        -logs workdir/clogs \\
        -outdir workdir \\
        -tumour-bam \$TUMOUR_BAM_ABS \\
        -normal-bam \$NORMAL_BAM_ABS \\
        -reference \$REF_FAI_ABS \\
        \$NORMAL_CN_ARG \\
        \$TUMOUR_CN_ARG \\
        \$IGNORE_ARG \\
        ${norm_cn_def} \\
        ${tum_cn_def} \\
        ${species_arg} \\
        ${assembly_arg} \\
        ${seqtype_arg} \\
        ${normal_prot} \\
        ${tumour_prot} \\
        ${contam_arg}

    # Compress and index VCFs
    MUTS_VCF=\$(ls \$WORKDIR_ABS/tmpCaveman/*.muts.ids.vcf)
    SNPS_VCF=\$(ls \$WORKDIR_ABS/tmpCaveman/*.snps.ids.vcf)

    bgzip \${MUTS_VCF}
    bgzip \${SNPS_VCF}

    # Get sample names for output naming
    MUTS_BASENAME=\$(basename \${MUTS_VCF})
    SNPS_BASENAME=\$(basename \${SNPS_VCF})

    # Go back to original directory for output collection
    cd \$ORIG_DIR

    # Copy to working directory for output
    cp \$WORKDIR_ABS/tmpCaveman/\${MUTS_BASENAME}.gz ./
    cp \$WORKDIR_ABS/tmpCaveman/\${SNPS_BASENAME}.gz ./

    tabix -p vcf \${MUTS_BASENAME}.gz
    tabix -p vcf \${SNPS_BASENAME}.gz
    """
}
