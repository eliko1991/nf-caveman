process CAVEMAN_SETUP {
    tag "setup"
    label 'process_low'
    container workflow.containerEngine == 'singularity' ? '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' : 'papaemmelab/docker-cgp:v1.1'

    input:
    tuple path(tumour_bam), path(tumour_bai), path(normal_bam), path(normal_bai), path(reference_fa), path(reference_fai), path(normal_cn), path(tumour_cn), path(ignore_file)

    output:
    path("workdir"), emit: workdir

    script:
    def normal_cn_arg     = (normal_cn && !normal_cn.name.startsWith('NO_FILE'))     ? "-normal-cn ${normal_cn}"         : ""
    def tumour_cn_arg     = (tumour_cn && !tumour_cn.name.startsWith('NO_FILE'))     ? "-tumour-cn ${tumour_cn}"         : ""
    def ignore_arg        = (ignore_file && !ignore_file.name.startsWith('NO_FILE')) ? "-ignore-file ${ignore_file}"     : ""
    def norm_cn_def       = params.norm_cn_default ? "-norm-cn-default ${params.norm_cn_default}" : ""
    def tum_cn_def        = params.tum_cn_default  ? "-tum-cn-default ${params.tum_cn_default}"   : ""
    def species_arg       = params.species         ? "-species ${params.species}"                 : ""
    def assembly_arg      = params.species_assembly ? "-species-assembly ${params.species_assembly}" : ""
    def seqtype_arg       = params.seqType         ? "-seqType ${params.seqType}"                 : ""
    def normal_prot       = params.normal_protocol ? "-normal-protocol ${params.normal_protocol}" : ""
    def tumour_prot       = params.tumour_protocol ? "-tumour-protocol ${params.tumour_protocol}" : ""
    def contam_arg        = params.normal_contamination ? "-normal-contamination ${params.normal_contamination}" : ""
    """
    mkdir -p workdir/clogs workdir/tmpCaveman

    caveman.pl \\
        -process setup \\
        -index 1 \\
        -threads ${task.cpus} \\
        -logs workdir/clogs \\
        -outdir workdir \\
        -tumour-bam ${tumour_bam} \\
        -normal-bam ${normal_bam} \\
        -reference ${reference_fai} \\
        ${normal_cn_arg} \\
        ${tumour_cn_arg} \\
        ${ignore_arg} \\
        ${norm_cn_def} \\
        ${tum_cn_def} \\
        ${species_arg} \\
        ${assembly_arg} \\
        ${seqtype_arg} \\
        ${normal_prot} \\
        ${tumour_prot} \\
        ${contam_arg}
    """
}
