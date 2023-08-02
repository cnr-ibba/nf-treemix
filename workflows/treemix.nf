
include { TREEMIX                                                   } from '../modules/local/treemix'
include { TREEMIX_PLOTS as PLOTS; TREEMIX_PLOTS as CONSENSUS_PLOTS  } from '../modules/local/treemix_plots'
include { OPTM                                                      } from '../modules/local/optm'
include { PHYLIP_CONSENSUS                                          } from '../modules/local/phylip_consensus'
include { TREEMIX_CONSENSUS                                         } from '../modules/local/treemix_consensus'


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
    PLOTS(treemix_out_ch)

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

        // collect all trees
        trees_input_ch = TREEMIX.out.treeout
            .map{ meta, path -> [meta, meta.migration, path]}
            .groupTuple(by: 1)
            .map{ meta, migration, path -> [[id: meta[0].id, migration: migration, iteration: 1], migration, path]}
            // .view()

        // create a consensus tree
        PHYLIP_CONSENSUS(trees_input_ch)
        ch_versions = ch_versions.mix(PHYLIP_CONSENSUS.out.versions)

        // all treemix_freq values in this channel are equal: take first one
        treemix_freq_ch = treemix_input_ch
            .first()
            .map{ meta, treemix_freq, migration, iteration -> [[id: meta.id], treemix_freq]}
            // .view()

        TREEMIX_CONSENSUS(treemix_freq_ch, PHYLIP_CONSENSUS.out.consensus_tre)
        ch_versions = ch_versions.mix(TREEMIX_CONSENSUS.out.versions)

        // collect treemix output
        treemix_consensus_out_ch = TREEMIX_CONSENSUS.out.cov
            .join(TREEMIX_CONSENSUS.out.covse)
            .join(TREEMIX_CONSENSUS.out.modelcov)
            .join(TREEMIX_CONSENSUS.out.treeout)
            .join(TREEMIX_CONSENSUS.out.vertices)
            .join(TREEMIX_CONSENSUS.out.edges)
            .join(TREEMIX_CONSENSUS.out.llik)
            // .view()

        // plot graphs
        CONSENSUS_PLOTS(treemix_consensus_out_ch)
    }

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}
