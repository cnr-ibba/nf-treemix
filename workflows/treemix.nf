
include { TREEMIX                       } from '../modules/local/treemix'
include { TREEMIX_PLOTS                 } from '../modules/local/treemix_plots'
include { OPTM                          } from '../modules/local/optm'


workflow TREEMIX_PIPELINE {
    take:
    treemix_input_ch    // channel: [ val(meta), path(treemix_freq), val(migration), val(iteration) ]]
    treemix_vertices    // path to vertices file (if any)
    treemix_edges       // path to edges file (if any)

    main:
    ch_versions = Channel.empty()

    TREEMIX(treemix_input_ch, treemix_vertices, treemix_edges)
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

    if ( params.n_iterations > 1 ) {
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
