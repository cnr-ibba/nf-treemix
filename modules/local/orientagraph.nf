process ORIENTAGRAPH {
    tag "$meta.id"
    label 'process_single'
    label 'process_long'
    label 'error_ignore'

    conda "bioconda::orientagraph=1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/orientagraph:1.1--hcfb5669_4':
        'biocontainers/orientagraph:1.1--hcfb5669_4' }"

    input:
    tuple val(meta), path(treemix_freq), val(migration), val(iteration)

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
    """
    orientagraph \\
        -i ${treemix_freq} \\
        ${outgroup_opt} \\
        ${k_opt} \\
        ${m_opt} \\
        -boostrap \\
        -seed ${seed} \\
        ${args} \\
        -o ${prefix}_m${migration}_i${iteration}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orientagraph: \$(echo \$(orientagraph --version 2>&1) | head -n1 | sed 's/^OrientAGraph //; s/ OrientAGraph is built from TreeMix.*//')
    END_VERSIONS
    """
}
