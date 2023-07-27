
include { ORIENTAGRAPH                                              } from '../modules/local/orientagraph'
include { TREEMIX_PLOTS as PLOTS; TREEMIX_PLOTS as CONSENSUS_PLOTS  } from '../modules/local/treemix_plots'
include { OPTM                                                      } from '../modules/local/optm'
include { SUMTREES                                                  } from '../modules/local/sumtrees'
include { ORIENTAGRAPH_CONSENSUS                                    } from '../modules/local/orientagraph_consensus'


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
    PLOTS(treemix_out_ch)

    if ( params.n_iterations > 1 ) {
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

        // create a consensus tree
        sumtrees_input_ch = ORIENTAGRAPH.out.treeout
            .map{ meta, path -> [meta, meta.migration, path]}
            .groupTuple(by: 1)
            .map{ meta, migration, path -> [[id: meta[0].id, migration: migration], migration, path]}
            // .view()

        SUMTREES(sumtrees_input_ch)
        ch_versions = ch_versions.mix(SUMTREES.out.versions)

        // all treemix_freq values in this channel are equal: take first one
        treemix_freq_ch = treemix_input_ch
            .first()
            .map{ meta, treemix_freq, migration, iteration -> [[id: meta.id], treemix_freq]}
            // .view()

        ORIENTAGRAPH_CONSENSUS(treemix_freq_ch, SUMTREES.out.consensus_tre)
        ch_versions = ch_versions.mix(ORIENTAGRAPH_CONSENSUS.out.versions)

        // collect treemix output
        treemix_consensus_out_ch = ORIENTAGRAPH_CONSENSUS.out.cov
            .join(ORIENTAGRAPH_CONSENSUS.out.covse)
            .join(ORIENTAGRAPH_CONSENSUS.out.modelcov)
            .join(ORIENTAGRAPH_CONSENSUS.out.treeout)
            .join(ORIENTAGRAPH_CONSENSUS.out.vertices)
            .join(ORIENTAGRAPH_CONSENSUS.out.edges)
            .join(ORIENTAGRAPH_CONSENSUS.out.llik)
            // .view()

        // plot graphs
        CONSENSUS_PLOTS(treemix_consensus_out_ch)
    }

    emit:
    versions = ch_versions              // channel: [ versions.yml ]
}
