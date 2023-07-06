#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// check parameters
if (!params.input) { exit 1, "Error: 'input' parameter not specified" }
if (!params.plink_prefix) { exit 1, "Error: 'plink_prefix' parameter not specified" }

include { PLINK_SUBSET } from './modules/local/plink_subset'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/nf-core/custom/dumpsoftwareversions/main'

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

    // return software version
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    TREEMIX_PIPELINE()
}
