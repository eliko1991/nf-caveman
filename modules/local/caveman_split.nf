process CAVEMAN_SPLIT {
    tag "split"
    label 'process_low'
    container workflow.containerEngine == 'singularity' ? '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' : 'papaemmelab/docker-cgp:v1.1'
    label 'process_long'

    input:
    path(workdir)
    tuple path(tumour_bam), path(tumour_bai), path(normal_bam), path(normal_bai), path(reference_fai), path(normal_cn), path(tumour_cn), path(ignore_file)

    output:
    path(workdir), emit: workdir

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
    # Get absolute paths before changing directory
    TUMOUR_BAM_ABS=\$(readlink -f ${tumour_bam})
    NORMAL_BAM_ABS=\$(readlink -f ${normal_bam})
    REF_FAI_ABS=\$(readlink -f ${reference_fai})

    # Handle optional files
    NORMAL_CN_ARG=""
    if [ -f "${normal_cn}" ] && [[ ! "${normal_cn}" =~ ^NO_FILE ]]; then
        NORMAL_CN_ARG="-normal-cn \$(readlink -f ${normal_cn})"
    fi

    TUMOUR_CN_ARG=""
    if [ -f "${tumour_cn}" ] && [[ ! "${tumour_cn}" =~ ^NO_FILE ]]; then
        TUMOUR_CN_ARG="-tumour-cn \$(readlink -f ${tumour_cn})"
    fi

    IGNORE_ARG=""
    if [ -f "${ignore_file}" ] && [[ ! "${ignore_file}" =~ ^NO_FILE ]]; then
        IGNORE_ARG="-ignore-file \$(readlink -f ${ignore_file})"
    fi

    NUM_CONTIGS=\$(wc -l < ${reference_fai} | tr -d ' ')

    # CaVEMan requires running from the same directory where setup was performed
    # Resolve symlink to get the actual setup directory (parent of workdir)
    SETUP_DIR=\$(dirname \$(readlink -f ${workdir}))
    cd \$SETUP_DIR

    for i in \$(seq 1 \$NUM_CONTIGS); do
        caveman.pl \\
            -process split \\
            -index \$i \\
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
    done
    """
}
