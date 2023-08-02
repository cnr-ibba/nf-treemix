
process TREEMIX {
    tag "$meta.id-m${meta.migration}-i${meta.iteration}"
    label 'process_single'
    label 'unlimited_time'
    label 'error_retry'

    conda "bioconda::treemix=1.13"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/treemix:1.13--hf961e7c_8':
        'biocontainers/treemix:1.13--hf961e7c_8' }"

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
    def g_opt = (treemix_vertices.name != 'NO_VERTICES' && treemix_edges.name != 'NO_EDGES') ? "-g ${treemix_vertices} ${treemix_edges}" : ""
    def outfile = (params.n_iterations > 1) ? "${prefix}.${iteration}.${migration}" : "${prefix}.${migration}"

    if( params.n_iterations > 1 )
        """
        treemix \\
            -i ${treemix_freq} \\
            ${outgroup_opt} \\
            ${k_opt} \\
            ${m_opt} \\
            -seed ${seed} \\
            -se \\
            -global \\
            ${args} \\
            -o ${outfile}

        if grep -q -i nan ${outfile}.llik
        then
            echo "Got an NaN in file"
            exit 1
        fi

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            treemix: \$(echo \$(treemix --version 2>&1) | sed 's/^TreeMix v. //; s/ \$Revision.*//')
        END_VERSIONS
        """
    else
        """
        treemix \\
            -i ${treemix_freq} \\
            ${g_opt} \\
            ${outgroup_opt} \\
            ${k_opt} \\
            ${m_opt} \\
            -se \\
            -global \\
            ${args} \\
            -o ${outfile}
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            treemix: \$(echo \$(treemix --version 2>&1) | sed 's/^TreeMix v. //; s/ \$Revision.*//')
        END_VERSIONS
        """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outfile = (params.n_iterations > 1) ? "${prefix}.${iteration}.${migration}" : "${prefix}.${migration}"
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
