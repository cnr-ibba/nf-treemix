process OPTM {
    tag "$method"
    label 'process_single'
    label 'error_ignore'

    container "bunop/r-optm:0.1"

    input:
    tuple val(meta), path(files)
    each(method)

    output:
    tuple val(meta), path("OptM_*.png"), emit: png
    tuple val(meta), path("OptM_*.tsv"), emit: tsv, optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outgroup_opt = params.treemix_outgroup ? "-root ${params.treemix_outgroup}" : ""
    """
    #!/usr/bin/env Rscript

    library(OptM)

    # latest orientagraph have the same llik format as treemix
    test <- optM(folder = ".", orientagraph = FALSE, method = "${method}", tsv = "OptM_${method}.tsv")
    png("OptM_${method}.png", width = 6, height = 6, units = 'in', res = 300)
    plot_optM(test, method = "${method}", plot = TRUE, pdf = NULL)
    title(paste("OptM", "${method}"))
    dev.off()
    """
}
