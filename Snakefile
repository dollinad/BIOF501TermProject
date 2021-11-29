## imports 
import os, sys 
import pandas as pd
import numpy as np

## Enviornment configurations 
workDir = "BIOF501TermProject/"
manifestFile = "00-helperfiles/manifest.txt"
accessionList = "00-helperfiles/accessionList.txt"
classifier = "00-helperfiles/gg-13-8-99-nb-classifier.qza"

## Output directories
sampleDir = "01-data/"
fastqcOut = "02-fastqc/"
multiqcOut = "03-multiqc/"
qiimeOut = "04-qiime2/"
visualsOut = "05-visuals/"
RPhyloseq = "06-RPhyloSeq/"

## Required lists
samples = []
fastqc_var = ["html", "zip"]
reads = ["1", "2"]

## making a list of samples 
with open(accessionList) as f:
    for line in f:
        sample_full = line.split("\n")
        samples.append(sample_full[0])

## Target rules 
rule all:
    input:
        expand(multiqcOut + "multiqc_report.html"),
        visualsOut + "01-rarefraction.png",
        visualsOut + "02-alpha_diversity.png",
        visualsOut + "03-relative_abundance.png",
        visualsOut + "04-beta_diversity.png",
        visualsOut + "05-heirarchal_clustering.png",
        visualsOut + "06-phylogenetics_tree.png"

## Step 1: download data
rule download_data:
    input:
        accessionList
    output:
        expand(sampleDir + "{sample}_{read}.fastq", sample=samples, read=reads)
    threads: 4
    message:
        "Downloading data from SRA."
    shell:
        #"cd 01-data/ && sh ../{input} | tee downloadLog.txt"
        """
        cd 01-data/
        echo "Running pre-fetch"
        prefetch --option-file ../{input} > DownloadLog.txt
        cd ..
        echo "Running fasterq-dump"
        cat {input} | xargs fasterq-dump -e 4 --outdir {sampleDir} 2> DownloadLog1.txt
        """

## Step 2: Fastqc
rule fastqc:
    input:
        inFile = expand(sampleDir + "{sample}_{read}.fastq", sample=samples, read=reads)
    output:
        expand(fastqcOut + "{sample}_{read}_fastqc.{var}", sample=samples, read=reads, var=fastqc_var)
    threads: 4
    message:
        "Running fastqc on the data."
    shell:
        "fastqc {input} -o {fastqcOut} -q -t 4"

## Step 3: Multiqc 
rule multiqc:
    input:
        inFile = expand(fastqcOut + "{sample}_{read}_fastqc.zip", sample=samples, read=reads)
    output:
        multiqcOut + "multiqc_report.html"
    params:
        "-q --no-data-dir"
    message:
        "Running multiqc on the data!"
    wrapper:
        "v0.80.1/bio/multiqc"

## needed for importing data into qiime2 
curDir = os.getcwd() +"/"
data = pd.read_csv(manifestFile, sep="\t", header=1, names=['sample-id', 'forward-absolute-filepath', 'reverse-absolute-filepath'])
data['forward-absolute-filepath'] = curDir + data['forward-absolute-filepath'].astype(str)
data['reverse-absolute-filepath'] = curDir + data['reverse-absolute-filepath'].astype(str)
data.to_csv(r'00-helperfiles/manifest-copy.txt', header=True, index=None, sep='\t')
manifestFile = "00-helperfiles/manifest-copy.txt"

## Step 4: Importing data into qiime2
rule qiime2_import_data:
    input:
        manFile = manifestFile,
        data = expand(sampleDir + "{sample}_{read}.fastq", sample=samples, read=reads)
    output:
        qiimeOut + "paired-end-data.qza"
    message:
        "Importing data into qiime2"
    shell: 
        """
        qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' \
        --input-path {input.manFile} --output-path {output} \
        --input-format PairedEndFastqManifestPhred33V2
        rm -r '01-data/' && touch rawDataRemoved.txt
        """


## Step 6: Summarize qiime2 data 
rule qiime2_summarize_vis:
    input:
        qiimeOut + "paired-end-data.qza"
    output:
        visualsOut + "paired-end-data.qzv"
    message:
        "Generating QC visualization"
    shell:
        """
        qiime demux summarize --i-data {input} \
        --o-visualization {output}
        """
## Step 7: Denoising and generation of ASVs
rule dada2_denoise_ASVs:
    message:
        """
        Using dada2 to denoise and generate ASVs. 
        Please view 03/multiqc_report.html and 05-visuals/paired-end-data.qzv which should already be open in your browser to input trimming localtions. 
        Since this workflow is designed for paired-end data, it needs four values: 
        1) Left trimming location for forward reads
        2) Left trimming location for reverse reads
        3) Truncation length for reverse reads
        4) Truncation length for forward reads

        Using default values for this run! 
        """
    input:
        data = qiimeOut + "paired-end-data.qza",
        vis = visualsOut + "paired-end-data.qzv"
    output:
        table = qiimeOut + "table.qza",
        rep_seqs = qiimeOut + "rep-seqs.qza",
        denoise_stats = qiimeOut + "denoising-stats.qza"
    threads: 4
    shell:
        "qiime dada2 denoise-paired --i-demultiplexed-seqs {input.data} \
        --p-n-threads 8 \
        --p-trim-left-f 20 --p-trim-left-r 20 \
        --p-trunc-len-f 275 --p-trunc-len-r 275 \
        --o-table {output.table} \
        --o-representative-sequences {output.rep_seqs} \
        --o-denoising-stats {output.denoise_stats}"

## Step 8: Generate rooted and unrooted trees
rule qiime2_phylogeny:
    input:
        qiimeOut + "rep-seqs.qza"
    output:
        aligned_rep_seqs = qiimeOut + "aligned-rep-seqs.qza",
        masked_aligned_rep_seqs = qiimeOut + "masked-aligned-rep-seqs.qza",
        unrooted_tree = qiimeOut + "unrooted-tree.qza",
        rooted_tree = qiimeOut + "rooted-tree.qza"
    threads: 4
    message:
        "Generating rooted and unrooted trees"
    shell: 
        "qiime phylogeny align-to-tree-mafft-fasttree \
        --p-n-threads 8 \
        --i-sequences {input} \
        --o-alignment {output.aligned_rep_seqs} \
        --o-masked-alignment {output.masked_aligned_rep_seqs} \
        --o-tree {output.unrooted_tree} \
        --o-rooted-tree {output.rooted_tree}"


## Step 9: Taxonomic classification
rule taxonomic_classification:
    input:
        inClassifier = classifier,
        reads = qiimeOut + "rep-seqs.qza"
    output:
        qiimeOut + "taxonomy.qza"
    threads: 4
    message:
        "Running a qiime2 pre-built GreenGenes classifier on representative sequences."
    shell:
        "qiime feature-classifier classify-sklearn \
        --i-classifier {input.inClassifier} \
        --i-reads {input.reads} \
        --o-classification {output}"

## Step 9: Prep the data for R analysis
rule R_AnalysisPrep:
    input:
        table = qiimeOut + "table.qza",
        rep_seqs = qiimeOut + "rep-seqs.qza",
        tax = qiimeOut + "taxonomy.qza",
        tree = qiimeOut + "rooted-tree.qza"
    output:
        directory(RPhyloseq)
    message:
        "Exporting qiime2 artifacts to load into R"
    shell:
        """
        qiime tools export --input-path {input.table} --output-path {output}
        biom convert -i {output}/feature-table.biom -o {output}/otu_table.tsv --to-tsv && cd {output}
        sed -i .bak '1d' otu_table.tsv
        sed -i .bak 's/#OTU ID//' otu_table.tsv
        cd ../
        qiime tools export --input-path {input.rep_seqs} --output-path {output}
        qiime tools export --input-path {input.tax} --output-path {output}
        qiime tools export --input-path {input.tree} --output-path {output}
        """

## Step 10: R analysis 
rule phyloseq_analysis:
    input:
        phyloDir = RPhyloseq,
        script = "scripts/R_analysis.R"
    output:
        visualsOut + "01-rarefraction.png",
        visualsOut + "02-alpha_diversity.png",
        visualsOut + "03-relative_abundance.png",
        visualsOut + "04-beta_diversity.png",
        visualsOut + "05-heirarchal_clustering.png",
        visualsOut + "06-phylogenetics_tree.png"
    message:
        "Performing visual anaysis using phyloseq package in R"
    shell:
        "Rscript {input.script} > Rlog.txt"
