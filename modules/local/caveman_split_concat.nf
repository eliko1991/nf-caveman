process CAVEMAN_SPLIT_CONCAT {
    tag "split_concat"
    label 'process_low'

    //container 'papaemmelab/docker-cgp:v1.1'
    container '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif'

    input:
    path(workdir)

    output:
    path(workdir), emit: workdir

    script:
    """
    caveman.pl \\
        -process split_concat \\
        -index 1 \\
        -threads ${task.cpus} \\
        -logs ${workdir}/clogs \\
        -outdir ${workdir}
    """
}
