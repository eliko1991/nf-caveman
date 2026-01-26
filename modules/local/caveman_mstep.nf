process CAVEMAN_MSTEP {
    tag "mstep_${index}"
    label 'process_medium'

    //container 'papaemmelab/docker-cgp:v1.1'
    container '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif'

    input:
    tuple path(workdir), val(index)

    output:
    tuple path(workdir), val(index), emit: done

    script:
    """
    caveman.pl \\
        -process mstep \\
        -index ${index} \\
        -threads ${task.cpus} \\
        -logs ${workdir}/clogs \\
        -outdir ${workdir}
    """
}
