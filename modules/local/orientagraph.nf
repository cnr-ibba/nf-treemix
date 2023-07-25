
process ORIENTAGRAPH {
    tag "$meta.id-m${meta.migration}-i${meta.iteration}"
    label 'process_single'
    label 'unlimited_time'
    label 'error_ignore'

    container "bunop/orientagraph:0.1"

    input:
    tuple val(meta), path(treemix_freq), val(migration), val(iteration)
    file(treemix_vertices)
    file(treemix_edges)

    output:
    tuple val(meta), path("*.cov.gz")       , emit: cov
    tuple val(meta), path("*.covse.gz")     , emit: covse
    tuple val(meta), path("*.modelcov.gz")  , emit: modelcov
    tuple val(meta), path("*.treeout.gz")   , emit: treeout
    tuple val(meta), path("*.vertices.gz")  , emit: vertices
    tuple val(meta), path("*.edges.gz")     , emit: edges
    tuple val(meta), path("*.llik")         , emit: llik
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outgroup_opt = params.treemix_outgroup ? "-root ${params.treemix_outgroup}" : ""
    def k_opt = params.treemix_k ? "-k ${params.treemix_k}" : ""
    def m_opt = migration ? "-m ${migration}" : ""
    def seed = (migration + task.attempt) * iteration
    def gf_opt = (treemix_vertices.name != 'NO_VERTICES' && treemix_edges.name != 'NO_EDGES') ? "-gf ${treemix_vertices} ${treemix_edges}" : ""
    def outfile = (params.n_iterations > 1) ? "${prefix}.${iteration}.${migration}" : "${prefix}.${migration}"

    if( params.n_iterations > 1 )
        """
        orientagraph \\
            -i ${treemix_freq} \\
            ${outgroup_opt} \\
            ${k_opt} \\
            ${m_opt} \\
            -seed ${seed} \\
            -se \\
            -global \\
            -allmigs \\
            -mlno \\
            ${args} \\
            -o ${outfile}
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            orientagraph: \$(echo \$(orientagraph --version 2>&1) | head -n1 | sed 's/^OrientAGraph //; s/ OrientAGraph is built from TreeMix.*//')
        END_VERSIONS
        """
    else
        """
        orientagraph \\
            -i ${treemix_freq} \\
            ${gf_opt} \\
            ${outgroup_opt} \\
            ${k_opt} \\
            ${m_opt} \\
            -se \\
            -global \\
            -allmigs \\
            -mlno \\
            ${args} \\
            -o ${outfile}
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            orientagraph: \$(echo \$(orientagraph --version 2>&1) | head -n1 | sed 's/^OrientAGraph //; s/ OrientAGraph is built from TreeMix.*//')
        END_VERSIONS
        """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outfile = "${prefix}.${migration}"
    """
    touch ${outfile}.cov.gz
    touch ${outfile}.covse.gz
    touch ${outfile}.modelcov.gz
    touch ${outfile}.treeout.gz
    touch ${outfile}.vertices.gz
    touch ${outfile}.edges.gz
    touch ${outfile}.llik
    touch versions.yml
    """
}
