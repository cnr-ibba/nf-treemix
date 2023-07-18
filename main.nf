#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// check parameters
if (!params.input) { exit 1, "Error: 'input' parameter not specified" }
if (!params.plink_prefix) { exit 1, "Error: 'plink_prefix' parameter not specified" }

include { PLINK_SUBSET                  } from './modules/local/plink_subset'
include { PLINK_FREQ                    } from './modules/local/plink_freq'
include { PLINK2TREEMIX                 } from './modules/local/plink2treemix'
include { TREEMIX_PIPELINE              } from './workflows/treemix'
include { ORIENTAGRAPH_PIPELINE         } from './workflows/orientagraph'
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from './modules/nf-core/custom/dumpsoftwareversions/main'


workflow CNR_IBBA {
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
    if ( params.single_migration || params.migrations == 0) {
        migrations_ch = Channel.value( params.migrations )
    } else {
        migrations_ch = Channel.of( 0..params.migrations )//.view()
    }

    // define bootstrap iterations
    if ( params.with_bootstrap ) {
        iterations_ch = Channel.of ( 1..params.bootstrap_iterations )//.view()
    } else {
        iterations_ch = Channel.value(1)
    }

    // check for previous treemix runs: read edges and vertices
    if  (params.treemix_edges && params.treemix_vertices ) {
        treemix_edges = file(params.treemix_edges)
        treemix_vertices = file(params.treemix_vertices)
    } else {
        // https://nextflow-io.github.io/patterns/optional-input/
        treemix_vertices = file("NO_VERTICES")
        treemix_edges = file("NO_EDGES")
    }

    // create treemix input channel
    treemix_input_ch = PLINK2TREEMIX.out.treemix_freq
        .combine(migrations_ch)
        .combine(iterations_ch)
        .map{ meta, path, migration, iteration -> [
            [id: meta.id, migration: migration, iteration: iteration], path, migration, iteration]}
        // .view()

    if ( params.with_orientagraph ) {
        ORIENTAGRAPH_PIPELINE(treemix_input_ch, treemix_vertices, treemix_edges)
        ch_versions = ch_versions.mix(ORIENTAGRAPH_PIPELINE.out.versions)
    } else {
        TREEMIX_PIPELINE(treemix_input_ch, treemix_vertices, treemix_edges)
        ch_versions = ch_versions.mix(TREEMIX_PIPELINE.out.versions)
    }

    // return software version
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    CNR_IBBA()
}
