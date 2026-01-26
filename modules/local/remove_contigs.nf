process REMOVE_CONTIGS {
    tag "remove_contigs"
    label 'process_single'

    //container 'papaemmelab/docker-cgp:v1.1'
    container '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif'

    input:
    path(workdir)

    output:
    path(workdir), emit: workdir

    script:
    """
    # Remove unwanted contigs (GL, hs, MT, NC sequences)
    cd ${workdir}/tmpCaveman

    rm -f splitList.GL* splitList.hs* splitList.MT splitList.NC* 2>/dev/null || true

    cd -
    """
}
