process CAVEMAN_SPLIT_CONCAT {
    tag "split_concat"
    label 'process_low'

    container 'papaemmelab/docker-cgp:v1.1'

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
