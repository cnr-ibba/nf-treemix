process PLINK2TREEMIX {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(plink_freq)

    output:
    tuple val(meta), path("*.treemix.frq.nomiss.gz"), emit: treemix_freq

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    plink2treemix.py \\
        ${plink_freq} \\
        ${prefix}.treemix.frq.gz
    zcat \\
        ${prefix}.treemix.frq.gz | sed '/ 0,0 /d' | gzip --best > ${prefix}.treemix.frq.nomiss.gz

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.treemix.frq.gz
    touch ${prefix}.treemix.frq.nomiss.gz
    """
}
