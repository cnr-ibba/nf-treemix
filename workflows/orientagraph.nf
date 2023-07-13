
include { ORIENTAGRAPH                  } from '../modules/local/orientagraph'
include { ORIENTAGRAPH_WITH_SAMPLING    } from '../modules/local/orientagraph'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow ORIENTAGRAPH_SIMPLE {
    take:
    treemix_freq    // channel: [ val(meta), path(treemix_freq) ]]

    main:
    ch_versions = Channel.empty()

    // define migration intervals
    migrations_ch = Channel.of( 1..params.migrations )//.view()

    treemix_input_ch = treemix_freq
        .combine(migrations_ch)
        .map{ meta, path, migration -> [
            [id: meta.id, migration: migration], path, migration]}
        // .view()

    ORIENTAGRAPH(treemix_input_ch)
    ch_versions = ch_versions.mix(ORIENTAGRAPH.out.versions)

    // collect treemix output
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

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}


workflow ORIENTAGRAPH_BOOTSTRAP {
    take:
    treemix_freq    // channel: [ val(meta), path(treemix_freq) ]]

    main:
    ch_versions = Channel.empty()

    // define migration intervals
    migrations_ch = Channel.of( 1..params.migrations )//.view()

    // define bootstrap iterations
    iterations_ch = Channel.of ( 1..params.treemix_iterations )//.view()

    treemix_input_ch = treemix_freq
        .combine(migrations_ch)
        .combine(iterations_ch)
        .map{ meta, path, migration, iteration -> [
            [id: meta.id, migration: migration, iteration: iteration], path, migration, iteration]}
        // .view()

    ORIENTAGRAPH_WITH_SAMPLING(treemix_input_ch)
    ch_versions = ch_versions.mix(ORIENTAGRAPH_WITH_SAMPLING.out.versions)

    // join treemix output channles
    treemix_out_ch = ORIENTAGRAPH_WITH_SAMPLING.out.cov
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.covse)
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.modelcov)
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.treeout)
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.vertices)
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.edges)
        .join(ORIENTAGRAPH_WITH_SAMPLING.out.llik)
        // .view()

    // plot graphs
    TREEMIX_PLOTS(treemix_out_ch)

    optM_input_ch = ORIENTAGRAPH_WITH_SAMPLING.out.cov.map{ meta, file -> file }
        .concat(ORIENTAGRAPH_WITH_SAMPLING.out.modelcov.map{ meta, file -> file })
        .concat(ORIENTAGRAPH_WITH_SAMPLING.out.llik.map{ meta, file -> file })
        .collect()
        .map{ it -> [[ id: "${file(params.input).getBaseName()}" ], it]}
        // .view()

    // calculate graphs with OptM
    methods = ["Evanno", "linear", "SiZer"]
    OPTM(optM_input_ch, methods)

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}
