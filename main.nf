#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// check parameters
if (!params.input) { exit 1, "Error: 'input' parameter not specified" }
if (!params.plink_prefix) { exit 1, "Error: 'plink_prefix' parameter not specified" }

include { PLINK_SUBSET                  } from './modules/local/plink_subset'
include { PLINK_FREQ                    } from './modules/local/plink_freq'
include { PLINK2TREEMIX                 } from './modules/local/plink2treemix'
include { TREEMIX                       } from './modules/local/treemix'
include { ORIENTAGRAPH                  } from './modules/local/orientagraph'
include { TREEMIX_PLOTS                 } from './modules/local/treemix_plots'
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from './modules/nf-core/custom/dumpsoftwareversions/main'


process OPTM {
    input:
    tuple val(meta), path(files)

    script:
    """
    echo ${files}
    """
}


workflow TREEMIX_PIPELINE {
    // collect software version
    ch_versions = Channel.empty()

    // getting input CSV with 3 columns (no header) FID IID LABELS
    samples_ch = Channel.fromPath(params.input)

    // getting plink input files
    plink_input_ch = Channel.fromPath( "${params.plink_prefix}.{bed,bim,fam}")
        .collect()
        .map( it -> [[ id: "${file(params.input).getBaseName()}" ], it[0], it[1], it[2]])
        //.view()

    // Extract samples from PLINK file
    PLINK_SUBSET(plink_input_ch, samples_ch)
    ch_versions = ch_versions.mix(PLINK_SUBSET.out.versions)

    // create a new input channel to calculate allele frequencines
    freq_ch = PLINK_SUBSET.out.bed
        .join(PLINK_SUBSET.out.bim)
        .join(PLINK_SUBSET.out.fam)
        //.view()

    // calculate MAF
    PLINK_FREQ(freq_ch, samples_ch)
    ch_versions = ch_versions.mix(PLINK_FREQ.out.versions)

    // convert PLINK output into treemix input
    PLINK2TREEMIX(PLINK_FREQ.out.freq)

    // define migration intervals
    migrations_ch = Channel.of( 1..params.migrations )//.view()

    // define bootstrap iterations
    iterations_ch = Channel.of ( 1..params.treemix_iterations )//.view()

    treemix_input_ch = PLINK2TREEMIX.out.treemix_freq
        .combine(migrations_ch)
        .combine(iterations_ch)
        .map{ meta, path, migration, iteration -> [
            [id: meta.id, migration: migration, iteration: iteration], path, migration, iteration]}
        // .view()

    // call treemix
    if ( params.with_treemix ) {
        TREEMIX(treemix_input_ch)
        ch_versions = ch_versions.mix(TREEMIX.out.versions)

        treemix_out_ch = TREEMIX.out.cov
            .join(TREEMIX.out.covse)
            .join(TREEMIX.out.modelcov)
            .join(TREEMIX.out.treeout)
            .join(TREEMIX.out.vertices)
            .join(TREEMIX.out.edges)
            .join(TREEMIX.out.llik)
            // .view()

        optM_input_ch = TREEMIX.out.cov.map{ meta, file -> file }
            .concat(TREEMIX.out.modelcov.map{ meta, file -> file })
            .concat(TREEMIX.out.llik.map{ meta, file -> file })
            .collect()
            .map{ it -> [[ id: "${file(params.input).getBaseName()}" ], it]}
            // .view()

    } else {
        ORIENTAGRAPH(treemix_input_ch)
        ch_versions = ch_versions.mix(ORIENTAGRAPH.out.versions)

        // join treemix output channles
        treemix_out_ch = ORIENTAGRAPH.out.cov
            .join(ORIENTAGRAPH.out.covse)
            .join(ORIENTAGRAPH.out.modelcov)
            .join(ORIENTAGRAPH.out.treeout)
            .join(ORIENTAGRAPH.out.vertices)
            .join(ORIENTAGRAPH.out.edges)
            .join(ORIENTAGRAPH.out.llik)
            // .view()

        optM_input_ch = ORIENTAGRAPH.out.cov.map{ meta, file -> file }
            .concat(ORIENTAGRAPH.out.modelcov.map{ meta, file -> file })
            .concat(ORIENTAGRAPH.out.llik.map{ meta, file -> file })
            .collect()
            .map{ it -> [[ id: "${file(params.input).getBaseName()}" ], it]}
            // .view()
    }

    OPTM(optM_input_ch)

    // plot graphs
    TREEMIX_PLOTS(treemix_out_ch)

    // return software version
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    TREEMIX_PIPELINE()
}
