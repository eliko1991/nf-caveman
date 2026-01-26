process CAVEMAN_SPLIT {
    tag "split"
    label 'process_low'

    //container 'papaemmelab/docker-cgp:v1.1'
    container '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif'

    input:
    path(workdir)
    tuple path(tumour_bam), path(tumour_bai), path(normal_bam), path(normal_bai), path(reference_fai)

    output:
    path(workdir), emit: workdir

    script:
    // Read reference.fai to get contig count for parallel splitting
    """
    NUM_CONTIGS=\$(wc -l < ${reference_fai} | tr -d ' ')

    for i in \$(seq 1 \$NUM_CONTIGS); do
        if [ -s "${reference_fai}" ]; then
            caveman.pl \\
                -process split \\
                -index \$i \\
                -threads ${task.cpus} \\
                -logs ${workdir}/clogs \\
                -outdir ${workdir} \\
                -tumour-bam ${tumour_bam} \\
                -normal-bam ${normal_bam} \\
                -reference ${reference_fai}
        fi
    done
    """
}
