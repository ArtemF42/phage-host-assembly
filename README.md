# Phage and Bacterial Genome Assembly Pipelines
This repository contains [Snakemake](https://snakemake.readthedocs.io/en/stable/) workflows for genome assembly and functional annotation of bacterial and bacteriophage genomes.

For details, see the following sections
- [Quality Control](#quality-control)
- [Taxonomic Classification](#taxonomic-classification)
- [Phage Assembly](#phage-assembly)
- [Bacterial Assembly](#bacterial-assembly)

### Important Notes
Snakemake allows you to use software from [Conda](https://www.anaconda.com/) environments. To enable this, specify the `conda` field in your `.smk` file, for example:

```snakemake
rule <RULE_NAME>:
    conda:
        <ENV_NAME>
```

Also, make sure to add the `--use-conda` flag when running the pipeline:

```bash
snakemake ... --use-conda
```

All pipelines require the samples argument. It can be provided in one of two formats:

```bash
--config samples=sample1,sample2,sample3

# Alternatively, provide a path to a text file where each line is a sample name
--config ...
```

## Quality Control

### Requirements
- [fastp](https://github.com/OpenGene/fastp)
- [MultiQC](https://github.com/MultiQC/MultiQC)

### Working Directory Layout
The pipeline expects the working directory to have the following structure:

```
working-directory/
└── raw-reads/
    ├── sample_1_R1.fq.gz
    ├── sample_1_R2.fq.gz
    ...
    ├── sample_N_R1.fq.gz
    └── sample_N_R2.fq.gz
```

Paired-end reads must be named as `sample_R1.fq.gz` and `sample_R2.fq.gz` and placed in the `raw-reads/` directory.

### Running the Pipeline
```bash
snakemake --snakefile ./pipelines/quality_control.smk \
    --directory /PATH/TO/WORKING/DIRECTORY \
    --config samples=/PATH/TO/SAMPLE/FILE
```

### Output
After the pipeline finishes, the following structure will be created:

```
working-directory/
├── raw-reads/
├── sample_1/
│   └── reads/
│       ├── sample_1_R1.fq.gz
│       └── sample_1_R2.fq.gz
...
├── sample_N/
│   └── reads/
│       ├── sample_N_R1.fq.gz
│       └── sample_N_R2.fq.gz
├── multiqc_report.html
└── multiqc_results/
```

## Taxonomic Classification
Sometimes sequencing reads may be contaminated with foreign DNA. This pipeline is designed to identify and remove non-target reads.

### Requirements
- [Kraken2](https://github.com/DerrickWood/kraken2)
- [Krona](https://github.com/marbl/Krona)
- [KrakenTools](https://github.com/jenniferlu717/KrakenTools)

You should also download an appropriate Kraken2 database (available [here](https://benlangmead.github.io/aws-indexes/k2)) and set an environment variable pointing to its location:

```bash
export KRAKEN2DB=/PATH/TO/KRAKEN2/DATABASE
```

### Working Directory Layout
The pipeline expects the working directory to have the following structure:

```
working-directory/
└── sample/
    └── reads/
        ├── sample_R1.fq.gz
        └── sample_R2.fq.gz
```

### Running the Pipeline
```bash
# Classify reads
snakemake --snakefile ./pipelines/taxonomic_classification.smk \
    --directory /PATH/TO/WORKING/DIRECTORY \
    --config samples=/PATH/TO/SAMPLE/FILE
```

### Output
After the pipeline runs, a new `taxonomy/` subdirectory will be created inside each sample directory, containing the following files:

```
working-directory/
└── sample/
    ├── reads/
    └── taxonomy/
        ├── sample.kraken2.output
        ├── sample.kraken2.report
        └── sample.krona.html
```

## Phage Assembly
This pipeline is a modified version of the one described in the paper ["Phage Genome Annotation: Where to Begin and End"](https://doi.org/10.1089/phage.2021.0015).

### Requirements
- [seqtk](https://github.com/lh3/seqtk)
- [SPAdes](https://github.com/ablab/spades)
- [Bandage](https://github.com/rrwick/Bandage) (optional)
- [CheckV](https://bitbucket.org/berkeleylab/CheckV)

You should also download the CheckV database and set the corresponding environment variable by running:

```bash
checkv download_database /PATH/TO/CHECKV/DATABASE
export CHECKVDB=/PATH/TO/CHECKV/DATABASE
```

### Running the Pipeline
```bash
# Genome Assembly
snakemake --snakefile ./pipelines/phage_assembly.smk assemble \
    --directory /PATH/TO/WORKING/DIRECTORY \
    --config sample=/PATH/TO/SAMPLE/FILE
```

## Bacterial Assembly