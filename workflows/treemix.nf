
include { TREEMIX                       } from '../modules/local/treemix'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow TREEMIX_PIPELINE {
    take:
    treemix_freq    // channel: [ val(meta), path(treemix_freq) ]]

    main:
    ch_versions = Channel.empty()

    // define migration intervals
    migrations_ch = Channel.of( 1..params.migrations )//.view()

    // define bootstrap iterations
    if ( params.with_bootstrap ) {
        iterations_ch = Channel.of ( 1..params.bootstrap_iterations )//.view()
    } else {
        iterations_ch = Channel.value(1)
    }

    treemix_input_ch = treemix_freq
        .combine(migrations_ch)
        .combine(iterations_ch)
        .map{ meta, path, migration, iteration -> [
            [id: meta.id, migration: migration, iteration: iteration], path, migration, iteration]}
        // .view()

    TREEMIX(treemix_input_ch)
    ch_versions = ch_versions.mix(TREEMIX.out.versions)

    // collect treemix output
    treemix_out_ch = TREEMIX.out.cov
        .join(TREEMIX.out.covse)
        .join(TREEMIX.out.modelcov)
        .join(TREEMIX.out.treeout)
        .join(TREEMIX.out.vertices)
        .join(TREEMIX.out.edges)
        .join(TREEMIX.out.llik)
        // .view()

        // plot graphs
    TREEMIX_PLOTS(treemix_out_ch)

    if ( params.with_bootstrap ) {
        // prepare OptM input
        optM_input_ch = TREEMIX.out.cov.map{ meta, file -> file }
            .concat(TREEMIX.out.modelcov.map{ meta, file -> file })
            .concat(TREEMIX.out.llik.map{ meta, file -> file })
            .collect()
            .map{ it -> [[ id: "${file(params.input).getBaseName()}" ], it]}
            // .view()

        // calculate graphs with OptM
        methods = ["Evanno", "linear", "SiZer"]
        OPTM(optM_input_ch, methods)
    }

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}
