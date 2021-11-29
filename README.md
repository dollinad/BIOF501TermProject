# Workflow for exploring microbiome profiles using QIIME2 and Phyloseq

## Table of Contents
1. [Background and hypothesis](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#background-and-hypothesis)
2. [Dependencies](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#dependencies)
3. [Workflow](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#workflow)
4. [Usage](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#usage)
5. [Input](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#input)
6. [Expected output](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#expected-output)
7. [References](https://github.com/dollinad/BIOF501TermProject/blob/main/README.md#references)

## Background and hypothesis
The recent advances in high-throughput sequencing has given us increasing evidence of the association of microbiome and human cancers. While many standalone platforms and R packages such as QIIME2, DADA2, phyloseq, and vegan have been published and widely used to conduct microbiome analysis, limited worflows have been developed that allow intergation of these tools. Here we use Snakemake, QIIME2 and Phyloseq to build a flexible, automated workflow to peform in-depth and reprdoucble analysis on any paired-end V4 16S rRNA microbiome data with two groups of interest and another variable that could account for variance in the dataset. 

The dataset that is will be used in this pipeline was first described by Tsementzi et. al (2020). The objective of this study was to compare vaginal microbiota in gynecologic cancers (endometrial/cervical) patients pre- and post- radiation therapy and healthy women. For the purposes of project, the dataset was randomly subsmapled to include five pre- and five post- radiation therapy (two groups of interest) from carival cancer patients of different ethnicity (another variable). The hypothesis that the pipleine aims to test is that the microbiome composition is different within the two groups of interest and some of the varerince in the dataset could be explained by an additional variable. The workflow aims to provide a visual report consisting of plots that describe rarefrcation curves, alpha and diversity, relative abundance of phyla in the two groups, hierarchical clustering, and phylogenetic trees. A complete list of accession IDs, and revlevant metadata of the dataset used is available in `00-helperfiles/metadata.txt`.

## Dependencies
The pipeline is built using snakemake and conda and it will be assumed that users have [git](https://github.com/git-guides/install-git), [conda](https://docs.conda.io/projects/conda/en/latest/index.html), and [snakemake](https://snakemake.readthedocs.io/en/stable/) installed. The main dependencies of this workflow include:
- `sra-toolkit=2.11.0`
- `qiime2=2021.8.0`
- `fastqc=0.11.9`
- `multiqc=1.11`
- `r-base=4.0.5`
- `phyloseq=1.34.0`
- `r-vegan=2.5_7`

Other minor dependencies are listed in `spec-file.txt`.

## Workflow
An overview of the workflow could be represented using a Directed Acyclic graph as shown below: 
<p align="center">
  <img src="https://user-images.githubusercontent.com/39140769/143794295-5b410f46-0dc9-4625-8c2e-6c66bb897679.png?raw=true">
</p>

The main steps of the workflow include:
1) **Download raw data**: This step needs an list of accession numbers to download raw paired-end data from the Sequence Read Archive (SRA) using `pre-fetch` and `fasterq-dump` commands from the `sra-toolkit`.
2) **Initial quality control**: The fastq files are then analyzed for qualiy checks using `FastQC` and `MultiQC`.
3) **Import data into QIIME2**: The fastq files will then be imported into a QIIME artifact (qza). After importing data, the pipeline will remove all raw data files downloaded from the SRA to optimize memory usage and therefore, these raw fastq files will not be accessible after the data has been imported into QIIME2. 
4) **Quality control using QIIME2**: The paied-end data artifact generated is then summaried using a QIIME2 visualization (qzv).
5) **Generation of ASVs**: Using DADA2 plugin in QIIME2, the paired-end data is denoised and an amplicon sequence variant (ASV) table is produced.
6) **Taxonomic classification**: The ASV table from DADA2 is passed into a QIIME2 pre-built Naive Bayes classifier to assign taxonomic labels to the generated ASVs. This pre-built calssifieris trained on Greengenes 13_8 99% OTUs full-length sequences.
7) **Phylogenetics**: The representative sequencs for the ASVs then undergo sequence alignment using MAFFT plugin in QIIME2 to generate aligned sequences, unrooted, and rooted trees in newick tree format. 
8) **Visual analysis**: The ASV table, representative sequences,rooted tree, and taxonomic classification is then used in R packages such as Phyloseq and vegan to understand differences/similarities in micrbiome composition between samples.

## Usage
1) Clone this repository move into the cloned directory. 
  ```
  git clone https://github.com/dollinad/BIOF501TermProject.git
  cd BIOF501termProject
  ```
2) Create and activate a conda environment named microbiome using a specification file. This environment will consist of required software and packages for the pipeline to run properly.
  ```
  conda create --name microbiome --file spec-file.txt
  conda activate microbiome
  ```
3) Finally, run the pipleline usingthe following command that allows parallelization of tasks by assigning 4 cores for the workflow to use. 
  ```
  snakemake --use-conda --cores 4
  ```
In one chunk, this is:
  ```
  git clone https://github.com/dollinad/BIOF501TermProject.git
  cd BIOF501termProject
  conda create --name microbiome --file spec-file.txt
  conda activate microbiome
  snakemake --use-conda --cores 4
  ```
  
## Input 
The workflow needs the following files in the `00-helperfiles` as input:
- `accessionList.txt`: A list of run accessions to download from SRA.

    |   |
    |---|
    |SRR6920043|
    |SRR6920044|
    |'''|
   
- `metadata.txt`: A tab-delimited text file containing three columns: SRA run ID, variable 1, and variable 2.
    
    |id|gynecologic_disord|ethnicity|
    |:---:|:---:|:---:|
    |SRR6920043|post-radiotherapy|African-american|
    |SRR6920044|pre-radiotherapy|African-american|
    |'''|'''|'''|
    
- `manifest.txt`: A tab-delimited text file containing three columns: SRA run ID, relative path for forward and reverse reads.

    |sample-id|forward-absolute-filepath|reverse-absolute-filepath|
    |:---:|:---:|:---:|
    |SRR6920043|01-data/SRR6920043_1.fastq|01-data/SRR6920043_2.fastq|
    |SRR6920044|01-data/SRR6920044_1.fastq|01-data/SRR6920044_2.fastq|
    |'''|'''|'''|
    
- `gg-13-8-99-nb-classifier.qza`: A pre-built classifier from QIIME2.

***Note:****Even though QIIME2 and the colname in `manifest.txt` need absolute paths to forward and reverse reads. it is sufficient to provide a relative path as the pipeline will automatically change this file to include an absolute path. 

## Expected output
The visual results from the pipeline can be found in the folder `05-visuals/` and are generated using the `R_analysis.R` script under the `scripts/` folder. The pipeline will generate the following results:

1) Quality control:

![Screen Shot 2021-11-28 at 5 25 02 PM](https://user-images.githubusercontent.com/39140769/143795228-cba214c6-379f-4a61-82b2-097b8891874b.png)

2) `05-visuals/01-rarefraction.png`:
![01-rarefraction](https://user-images.githubusercontent.com/39140769/143795233-d32890b9-21a2-4888-80df-eb1b0c72dbab.png)

3) `05-visuals/02-alpha-diversity.png`:
![02-alpha_diversity](https://user-images.githubusercontent.com/39140769/143795239-565eede6-6f24-4b99-97ac-0f149893eb3a.png)

4) `05-visuals/relative_abundance.png`:
![03-relative_abundance](https://user-images.githubusercontent.com/39140769/143795241-f4daa325-e72e-48e4-bd4c-d66239a2e347.png)

5) `05-visuals/04-beta_diversity.png`:
![04-beta_diversity](https://user-images.githubusercontent.com/39140769/143795256-91a2961f-9b75-4e4c-8716-f9fa902a8f20.png)

6) `05-visuals/05-heirarchal_clustering.png`:
![05-heirarchal_clustering](https://user-images.githubusercontent.com/39140769/143795264-30a31047-78a3-44b4-b3ca-d48c6194aa02.png)

7) `05-visuals/06-phylogenetics_tree.png`:
![06-phylogenetics_tree](https://user-images.githubusercontent.com/39140769/143795271-a1e90bbc-9dba-4da0-9ca4-2beb00cfd5e2.png)

Other intermediate output files that could be used for additional downstream analysis include `04-qiime2/table.qza` (ASV table), `04-qiime2/rep-seqs.qza` (representative sequences for ASVs), `04-qiime2/aligned-rep-seqs.qza`, `04-qiime2/rooted-tree.qza`, `04-qiime2/unrooted-tree.qza`.

Since the above mentioned files are QIIME2 artifacts, they would be exported from the compressed object before analysis. For example, to export the ASV table use the following command.
```
qiime tools export --input-path 04-qiime2/table.qza --output-path outputDir/
```

## References
