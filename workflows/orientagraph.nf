
include { ORIENTAGRAPH                  } from '../modules/local/orientagraph'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow ORIENTAGRAPH_PIPELINE {
    take:
    treemix_input_ch    // channel: [ val(meta), path(treemix_freq), val(migration), val(iteration) ]]
    treemix_vertices    // path to vertices file (if any)
    treemix_edges       // path to edges file (if any)

    main:
    ch_versions = Channel.empty()

    ORIENTAGRAPH(treemix_input_ch, treemix_vertices, treemix_edges)
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
