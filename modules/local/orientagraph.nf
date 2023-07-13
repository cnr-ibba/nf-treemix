
process ORIENTAGRAPH {
    tag "$meta.id-m${meta.migration}"
    label 'process_single'
    label 'process_long'
    label 'error_ignore'

    container "bunop/orientagraph:0.1"

    input:
    tuple val(meta), path(treemix_freq), val(migration)
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
    """
    orientagraph \\
        -i ${treemix_freq} \\
        ${outgroup_opt} \\
        ${k_opt} \\
        ${m_opt} \\
        -se \\
        -global \\
        -allmigs \\
        -mlno \\
        ${args} \\
        -o ${prefix}.${migration}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orientagraph: \$(echo \$(orientagraph --version 2>&1) | head -n1 | sed 's/^OrientAGraph //; s/ OrientAGraph is built from TreeMix.*//')
    END_VERSIONS
    """
}


process ORIENTAGRAPH_WITH_SAMPLING {
    tag "$meta.id-m${meta.migration}-i${iteration}"
    label 'process_single'
    label 'process_long'
    label 'error_ignore'

    container "bunop/orientagraph:0.1"

    input:
    tuple val(meta), path(treemix_freq), val(migration), val(iteration)

    output:
    tuple val(meta), path("*.treemix.gz")   , emit: treemix
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
    # Generate bootstrapped input file with ~80% of the SNP loci
    # inspired from https://rfitak.shinyapps.io/OptM/
    gunzip -c ${treemix_freq} | awk 'BEGIN {srand(${seed})} { if (NR==1) {print \$0} else if (rand() <= .8) print \$0}' | gzip > ${prefix}.${iteration}.${migration}.treemix.gz

    orientagraph \\
        -i ${prefix}.${iteration}.${migration}.treemix.gz \\
        ${outgroup_opt} \\
        ${k_opt} \\
        ${m_opt} \\
        -seed ${seed} \\
        -se \\
        -global \\
        -allmigs \\
        -mlno \\
        ${args} \\
        -o ${prefix}.${iteration}.${migration}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orientagraph: \$(echo \$(orientagraph --version 2>&1) | head -n1 | sed 's/^OrientAGraph //; s/ OrientAGraph is built from TreeMix.*//')
    END_VERSIONS
    """
}
