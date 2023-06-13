# description 

nfcore/rnaseq is a bioinformatics analysis pipeline used for RNA sequencing data. it iterate pretty fast so I suggest check the offical release frequently.

This repo is just a copy of the working directory I usually set up for my own project. 

## Quick Start

For a single study, you can use the following steps to set up the environment and run the pipeline.

### 1. setup folders and copy data and reference files

Prepare the following folders and files. If working on hybrid species with 2 reference files, you might want to merger them into one file.

```bash
mkdir fastq
mkdir results
mkdir ref

cp /*fastq.gz fastq/ # make sure the fastq files are compressed

cp /genome_reference.fa ref/genome.fa
cp /genome_annotation.gff ref/annotation.gff # if using phytozome, use the *gene_exons.gff3.gz and change the extension into gff
```

### 2. setup the nfcore/rnaseq environment

Here I provided example `input.csv` and `nf-params.json` files. You must modify the `input.csv` to point to the correct fastq files. I suggest go throught the latest version of [nfcore/rnaseq](https://nf-co.re/rnaseq) to see if there are any changes to the `nf-params.json` file. Things that need a little attention are the following lines in the `nf-params.json` file due to the format of the phytozome annotation file, please adjust accordingly:

```
"gtf_extra_attributes": "Name",
"featurecounts_group_type": "",
"featurecounts_feature_type": "",
"skip_biotype_qc": true,
```

### 3. run the pipeline on sapelo2

I provided an example `run.sh` file. You can modify it to fit your needs. Make sure to adjust the job name, email, headers, and current version using. Then submit the job to the cluster:

```bash
sbatch run.sh
```

## batch processing

`pysradb_SRA2nfcore.ipynb` contains an example of how I use pysradb to download SRA files and then use nfcore/rnaseq to process them.

## FAQ

1.  whenever a run failed and you want to resubmit it, make sure to change the run name in the `run.sh` or it will not run. 
