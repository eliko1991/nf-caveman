process CAVEMAN_MERGE {
    tag "merge"
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
        -process merge \\
        -index 1 \\
        -threads ${task.cpus} \\
        -logs ${workdir}/clogs \\
        -outdir ${workdir}
    """
}
