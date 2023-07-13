process TREEMIX_PLOTS {
    tag "$meta.id-m${meta.migration}-i${meta.iteration}"
    label 'process_single'

    conda "bioconda::treemix=1.13"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/treemix:1.13--hf961e7c_8':
        'biocontainers/treemix:1.13--hf961e7c_8' }"

    input:
    tuple val(meta), path(cov), path(covse), path(modelcov), path(treeout), path(vertices), path(edges), path(llik)

    output:
    tuple val(meta), path("*_tree.png"), emit: tree

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def stem = llik.getBaseName()
    """
    #!/usr/bin/env Rscript

    source("/usr/local/bin/plotting_funcs.R")

    png("${stem}_tree.png", width = 6, height = 6, units = 'in', res = 300)
    plot_tree("${stem}", cex=0.8)
    title(paste("${meta.id}", "${meta.migration}", "migrations"))
    dev.off()
    """

    stub:
    def stem = llik.getBaseName()
    """
    touch ${stem}_tree.png
    """
}
