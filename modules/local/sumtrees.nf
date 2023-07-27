process SUMTREES {
    tag "${meta.id}-m${migration}"
    label 'process_single'

    conda "bioconda::dendropy==4.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/dendropy:4.6.1--pyhdfd78af_0':
        'biocontainers/dendropy:4.6.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), val(migration), path(treeout)

    output:
    tuple val(meta), val(migration), path("*.tre")  , emit: consensus_tre
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outfile = "${prefix}.${migration}.consensus.tre"
    """
    trees=(${treeout})
    for tree in "\${trees[@]}" ; do \\
        head -n1 <(zcat \$tree) ; \\
    done | \\
    sumtrees.py \\
        --rooted \\
        --source-format newick \\
        --multiprocessing ${task.cpus} \\
        --quiet \\
        --labels keep \\
        --suppress-annotations \\
        --no-taxa-block \\
        --no-analysis-metainformation \\
        ${args} \\
        --replace \\
        - | \\
    sed 's/^\\[&R\\] //' > ${outfile}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sumtrees.py: \$(sumtrees.py --version | sed '4!d;s/.*Version //;s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outfile = "${prefix}.${migration}.consensus.tre"
    """
    touch ${outfile}
    touch versions.yml
    """
}
