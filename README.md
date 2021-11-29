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
The recent advances in high-throughput sequencing has enables us to 


## Dependencies
The main dependencies of this workflow include

## Workflow
An overview of the workflow could be represented using a Directed Acyclic graph as shown below: 
![Screen Shot 2021-11-28 at 5 07 39 PM](https://user-images.githubusercontent.com/39140769/143794295-5b410f46-0dc9-4625-8c2e-6c66bb897679.png)

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

## Expected output
The visual results from the pipeline can be found in the folder `05-visuals/` and are generated using the `R_analysis.R` script under the `scripts/` folder. 

![Screen Shot 2021-11-28 at 5 25 02 PM](https://user-images.githubusercontent.com/39140769/143795228-cba214c6-379f-4a61-82b2-097b8891874b.png)

![01-rarefraction](https://user-images.githubusercontent.com/39140769/143795233-d32890b9-21a2-4888-80df-eb1b0c72dbab.png)

![02-alpha_diversity](https://user-images.githubusercontent.com/39140769/143795239-565eede6-6f24-4b99-97ac-0f149893eb3a.png)

![03-relative_abundance](https://user-images.githubusercontent.com/39140769/143795241-f4daa325-e72e-48e4-bd4c-d66239a2e347.png)

![04-beta_diversity](https://user-images.githubusercontent.com/39140769/143795256-91a2961f-9b75-4e4c-8716-f9fa902a8f20.png)

![05-heirarchal_clustering](https://user-images.githubusercontent.com/39140769/143795264-30a31047-78a3-44b4-b3ca-d48c6194aa02.png)

![06-phylogenetics_tree](https://user-images.githubusercontent.com/39140769/143795271-a1e90bbc-9dba-4da0-9ca4-2beb00cfd5e2.png)


## References
