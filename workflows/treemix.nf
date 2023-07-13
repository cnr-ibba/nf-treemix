
include { TREEMIX                       } from '../modules/local/treemix'
include { TREEMIX_WITH_SAMPLING         } from '../modules/local/treemix'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow TREEMIX_SIMPLE {
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

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}


workflow TREEMIX_BOOTSTRAP {
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

    TREEMIX_WITH_SAMPLING(treemix_input_ch)
    ch_versions = ch_versions.mix(TREEMIX_WITH_SAMPLING.out.versions)

    // collect treemix output
    treemix_out_ch = TREEMIX_WITH_SAMPLING.out.cov
        .join(TREEMIX_WITH_SAMPLING.out.covse)
        .join(TREEMIX_WITH_SAMPLING.out.modelcov)
        .join(TREEMIX_WITH_SAMPLING.out.treeout)
        .join(TREEMIX_WITH_SAMPLING.out.vertices)
        .join(TREEMIX_WITH_SAMPLING.out.edges)
        .join(TREEMIX_WITH_SAMPLING.out.llik)
        // .view()

        // plot graphs
    TREEMIX_PLOTS(treemix_out_ch)

    // prepare OptM input
    optM_input_ch = TREEMIX_WITH_SAMPLING.out.cov.map{ meta, file -> file }
        .concat(TREEMIX_WITH_SAMPLING.out.modelcov.map{ meta, file -> file })
        .concat(TREEMIX_WITH_SAMPLING.out.llik.map{ meta, file -> file })
        .collect()
        .map{ it -> [[ id: "${file(params.input).getBaseName()}" ], it]}
        // .view()

    // calculate graphs with OptM
    methods = ["Evanno", "linear", "SiZer"]
    OPTM(optM_input_ch, methods)

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}
