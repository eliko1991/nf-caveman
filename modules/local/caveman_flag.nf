process CAVEMAN_FLAG {
    tag "flag"
    label 'process_medium'
    container workflow.containerEngine == 'singularity' ? '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' : 'papaemmelab/docker-cgp:v1.1'
    label 'process_long'
    container workflow.containerEngine == 'singularity' ? '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' : 'papaemmelab/docker-cgp:v1.1'

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    tuple path(muts_vcf), path(tumour_bam), path(tumour_bai), path(normal_bam), path(normal_bai), path(reference_fa), path(reference_fai), path(flag_bed_files), path(germline_indel), path(unmatched_vcf), path(annot_bed_files), path(flag_config), path(flag_to_vcf_config)

    output:
    path("*.flagged.muts.vcf.gz"),     emit: vcf
    path("*.flagged.muts.vcf.gz.tbi"), emit: vcf_tbi

    script:
    def study_type = params.seqType == 'pulldown' ? 'pulldown' : 'genomic'
    def flag_config_arg = (flag_config && !flag_config.name.startsWith('NO_FILE')) ? "-c ${flag_config}" : ""
    def flag_to_vcf_arg = (flag_to_vcf_config && !flag_to_vcf_config.name.startsWith('NO_FILE')) ? "-v ${flag_to_vcf_config}" : ""
    def annot_arg = (annot_bed_files && !annot_bed_files.name.startsWith('NO_FILE')) ? "-ab ${annot_bed_files}" : ""
    """
    # Get output name from input VCF
    OUT_NAME=\$(basename ${muts_vcf} .muts.ids.vcf.gz).flagged.muts.vcf

    cgpFlagCaVEMan.pl \\
        -i ${muts_vcf} \\
        -o \${OUT_NAME} \\
        -m ${tumour_bam} \\
        -n ${normal_bam} \\
        -b ${flag_bed_files} \\
        -g ${germline_indel} \\
        -umv ${unmatched_vcf} \\
        -s ${params.species} \\
        -t ${study_type} \\
        -ref ${reference_fai} \\
        ${flag_config_arg} \\
        ${flag_to_vcf_arg} \\
        ${annot_arg}

    bgzip \${OUT_NAME}
    tabix -p vcf \${OUT_NAME}.gz
    """
}
