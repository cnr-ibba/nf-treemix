
include { ORIENTAGRAPH                  } from '../modules/local/orientagraph'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow ORIENTAGRAPH_PIPELINE {
    take:
    treemix_freq    // channel: [ val(meta), path(treemix_freq) ]]

    main:
    ch_versions = Channel.empty()

    // define migration intervals
    if ( params.single_migration || params.migrations == 0) {
        migrations_ch = Channel.value( params.migrations )
    } else {
        migrations_ch = Channel.of( 1..params.migrations )//.view()
    }

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

    // plot graphs
    TREEMIX_PLOTS(treemix_out_ch)

    if ( params.with_bootstrap ) {
        // prepare OptM input
        optM_input_ch = ORIENTAGRAPH.out.cov.map{ meta, file -> file }
            .concat(ORIENTAGRAPH.out.modelcov.map{ meta, file -> file })
            .concat(ORIENTAGRAPH.out.llik.map{ meta, file -> file })
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
