#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// check parameters
if (!params.input) { exit 1, "Error: 'input' parameter not specified" }
if (!params.plink_prefix) { exit 1, "Error: 'plink_prefix' parameter not specified" }

workflow TREEMIX_PIPELINE {
    // getting plink input files
    plink_input_ch = Channel.fromPath( "${params.plink_prefix}.{bim,bed,fam}")
        .collect().view()
}

workflow {
    TREEMIX_PIPELINE()
}
