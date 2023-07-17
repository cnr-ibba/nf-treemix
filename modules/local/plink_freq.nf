process PLINK_FREQ {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::plink=1.90b6.21"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink:1.90b6.21--h779adbc_1':
        'biocontainers/plink:1.90b6.21--h779adbc_1' }"

    input:
    tuple val(meta), path(bed), path(bim), path(fam)
    path(samples)

    output:
    tuple val(meta), path("*.frq.strat.gz") , emit: freq
    tuple val(meta), path("*.imiss")        , emit: imiss
    tuple val(meta), path("*.lmiss")        , emit: lmiss
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def species_opt = "${params.plink_species_opts}"
    """
    plink \\
        ${species_opt} \\
        --bed ${bed}  \\
        --bim ${bim}  \\
        --fam ${fam}  \\
        --threads $task.cpus \\
        $args \\
        --freq gz \\
        --missing \\
        --within ${samples} \\
        --out $prefix
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink: \$(echo \$(plink --version) | sed 's/^PLINK v//;s/64.*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.frq.strat.gz
    touch ${prefix}.imiss
    touch ${prefix}.lmiss
    touch versions.yml
    """
}
