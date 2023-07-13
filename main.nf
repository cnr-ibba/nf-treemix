#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// check parameters
if (!params.input) { exit 1, "Error: 'input' parameter not specified" }
if (!params.plink_prefix) { exit 1, "Error: 'plink_prefix' parameter not specified" }

include { PLINK_SUBSET                      } from './modules/local/plink_subset'
include { PLINK_FREQ                        } from './modules/local/plink_freq'
include { PLINK2TREEMIX                     } from './modules/local/plink2treemix'
include { TREEMIX_SIMPLE; TREEMIX_BOOTSTRAP } from './workflows/treemix'
include { CUSTOM_DUMPSOFTWAREVERSIONS       } from './modules/nf-core/custom/dumpsoftwareversions/main'


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

    if ( params.with_bootstrap ) {
        if ( params.with_orientagraph ) {

        } else {
            TREEMIX_BOOTSTRAP(PLINK2TREEMIX.out.treemix_freq)
            ch_versions = ch_versions.mix(TREEMIX_BOOTSTRAP.out.versions)
        }
    } else {
        if ( params.with_orientagraph ) {

        } else {
            TREEMIX_SIMPLE(PLINK2TREEMIX.out.treemix_freq)
            ch_versions = ch_versions.mix(TREEMIX_SIMPLE.out.versions)
        }
    }

    // return software version
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

workflow {
    CNR_IBBA()
}
