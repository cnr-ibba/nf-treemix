
# nf-treemix

A nextflow pipeline which executes *treemix* on a population of interest

## Background

This pipeline is an attempt to call [treemix](https://bitbucket.org/nygcresearch/treemix/wiki/Home)
on a PLINK binary file. All the steps required to produce the *treemix* input files
are managed within this pipeline.
This pipeline implement also a bootstrapping version of *treemix*, and can evaluate
results with the [OptM](https://cran.r-project.org/web/packages/OptM/index.html)
package. It's also possible to replace *treemix* with [OrientaGraph](https://github.com/sriramlab/OrientAGraph)

## Data preparation

This pipeline require at least two input file. First is a PLINK binary files already
filtered by missing genotypes or samples. The second is a TSV file required to extract
the samples of interest from the PLINK file and to assign label ids to treemix cluster.
This file need to have 3 columns: `FID`, `IID` and `cluster ID`: You can derive the first
two columns form the plink binary file (the `.fam`) file. The third column could be
equal to the first column if you want to use the `FID` as treemix `cluster IDs`, or
you could provide different cluster ids, for example if you want more FID be included
in the same group or vice-versa.

## Calling the pipeline

The simplest way to calling this pipeline is to call nextflow and provide your
plink binary file *prefix* (the same way you use to specify it with PLINK)
and the samples TSV as a parameters, for example:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix>
```

You can provide outgroup to *treemix* simply by passing the `--treemix_outgroup`
option, for example:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix> --treemix_outgroup <you outgroup ID>
```

If you want to test different migration hypothesis, you could provide the
migrations steps with the `--migrations` parameter:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix> --migrations 5
```

This will call treemix 5 times, each one evaluating a different migration. If you
want to call a single migration (for example, only *M=5*), you can add `--single_migration`
option to nextflow command line:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix> --migrations 5 --single_migration
```

You can perform a bootstrap evaluation with treemix providing `--with_bootstrap`
and `--bootstrap_iterations` parameters. This pipeline will perform a boostrapping
of 80% of the SNP data in each iterations:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix> --migrations 5 --with_bootstrap \
    --bootstrap_iterations 5
```

If you prefer calling *OrientaGraph* instead of *treemix*, you can use the
`--with_orientagraph` option:

```bash
nexflow run cnr-ibba/nf-treemix -profile singularity --input <samples TSV> \
    --plink_prefix <the plink prefix> --migrations 5 --with_bootstrap \
    --bootstrap_iterations 5 --with_orientagraph
```

### Creating a configuration file

The best way to manage this pipeline is to create a custom configuration file in
which you can specify the parameters you need:

```txt
params {
    // pipeline input args
    input                   = "<your TSV file>"
    plink_prefix            = "<the PLINK prefix>"
    migrations              = 5

    // treemix options
    treemix_outgroup        = "<your outgroup id>"
    treemix_k               = 1000

    // PLINK options (required to subset data properly)
    plink_species_opts      = '--chr-set 26 no-xy no-mt --allow-no-sex'

    // pipeline option
    with_bootstrap          = true
    bootstrap_iterations    = 5
}
```

You can have a list of all the available options by inspecting the
[nextflow.config](https://github.com/cnr-ibba/nf-treemix/blob/master/nextflow.config)
file of this pipeline
