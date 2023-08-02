process PHYLIP_CONSENSUS {
    tag "${meta.id}-m${migration}"
    label 'process_single'

    conda "bioconda::phylip==3.697"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/phylip:3.697--h470a237_0':
        'biocontainers/phylip:3.697--h470a237_0' }"

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
    def rooted_opt = params.treemix_outgroup ? "--rooted" : ""
    if( params.treemix_outgroup )
        """
        trees=(${treeout})
        for tree in "\${trees[@]}" ; do \\
            head -n1 <(zcat \$tree) ; \\
        done > intree

        posOutgroup=\$(head -1 intree | tr "," "\\n" | grep ${params.treemix_outgroup} -n | cut -d":" -f1)

        cat <<-END > params.txt
        O
        \$posOutgroup
        Y
        END

        rm -f outfile outtree

        consense < params.txt

        cat outtree | tr -d "\\n" > ${outfile}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            consense: 3.697
        END_VERSIONS
        """

    else
        """
        trees=(${treeout})
        for tree in "\${trees[@]}" ; do \\
            head -n1 <(zcat \$tree) ; \\
        done > intree

        cat <<-END > params.txt
        Y
        END

        rm -f outfile outtree

        consense < params.txt

        cat outtree | tr -d "\\n" > ${outfile}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            consense: 3.697
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
