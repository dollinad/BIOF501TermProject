## This chunk will import necessary libraries and import all the required data from qiime2 
suppressMessages(library(phyloseq))
suppressMessages(library(vegan))
suppressMessages(library(Biostrings))
suppressMessages(library(ggplot2))
suppressMessages(library(RColorBrewer))
suppressMessages(library(ape))
suppressMessages(library(tidyverse))
suppressMessages(library(dendextend))
suppressMessages(library(plyr))
options(warn=-1)
otu <- read.table("06-RPhyloSeq/otu_table.tsv", row.names = 1, header = TRUE, sep = "\t")
tax <- read.table("06-RPhyloSeq/taxonomy.tsv", row.names = 1, header = TRUE, sep = "\t") %>%
  as_tibble() %>%
  separate (Taxon, sep="; ", c("Kingdom","Phylum","Class","Order","Family","Genus","Species")) %>% 
  as.data.frame() %>%
  select(-Confidence)
rep.seqs <- Biostrings::readDNAStringSet("06-RPhyloSeq/dna-sequences.fasta", format = "fasta")
sample.data <- read.table("00-helperfiles/metadata.txt", row.names = 1, header = TRUE, sep = "\t", stringsAsFactors=T)
tree <- read_tree("06-RPhyloSeq/tree.nwk")

otu.table <- phyloseq::otu_table(otu, taxa_are_rows = TRUE)
names <- row.names(otu)
rownames(tax) <- names 
tax_matrix <- as.matrix(tax)
tax.table <- phyloseq::tax_table(tax_matrix)
expt <- phyloseq::phyloseq(otu.table, sample_data(sample.data), rep.seqs, tax.table, tree)
col_names <- colnames(sample.data)

## Rarefraction curve - 1 variable 
png("05-visuals/01-rarefraction.png", units="cm", width=20, height=15, res = 300, pointsize = 6)
rarecurve(t(otu.table), step = 50, cex=0.5, col = brewer.pal(5, "Dark2") [sample.data[, 1]], label = FALSE, lwd=2)
legend("topright", legend = levels(sample.data[, 1]), col=brewer.pal(5, "Dark2"), lty=1, lwd = 3)
dev.off()

## Alpha diveristy - 2 variables 
expt_trimmed <- prune_taxa(taxa_sums(expt)>0, expt)
png("05-visuals/02-alpha_diversity.png", units="cm", width=20, height=15, res = 300, pointsize = 6)
p <-  plot_richness(expt_trimmed, x=col_names[1], color = col_names[2], nrow = 2)
(p + geom_boxplot(data=p$data, aes(x=col_names[1], y=value, color=NULL), alpha=0.1))
dev.off()

## Relative abundance 
expt.rarefied = rarefy_even_depth(expt, rngseed=1, sample.size=0.9*min(sample_sums(expt)), replace=F)
expt.phylum = tax_glom(expt.rarefied, taxrank="Phylum", NArm=FALSE)
png("05-visuals/03-relative_abundance.png", units = "cm", width = 20, height = 15, res = 300, pointsize = 6)
plot_bar(expt.phylum, fill="Phylum") + facet_wrap(~col_names[1], scales= "free_x", nrow=1)
dev.off()

## beta diversity - 2 variables 
dist_methods <- unlist(distanceMethodList)
dist_methods = dist_methods[-which(dist_methods=="ANY")]
plist <- vector("list", length(dist_methods))
names(plist) = dist_methods
for( i in dist_methods ){
  iDist <- phyloseq::distance(expt.rarefied, method=i)
  iMDS  <- ordinate(expt.rarefied, "MDS", distance=iDist)
  p <- NULL
  p <- plot_ordination(expt.rarefied, iMDS, color=col_names[1], shape=col_names[2])
  p <- p + ggtitle(paste("MDS using distance method ", i, sep=""))
  plist[[i]] = p
}

df = ldply(plist, function(x) x$data)
names(df)[1] <- "distance"
p = ggplot(df, aes(Axis.1, Axis.2, color=df[, col_names[1]], shape=df[, col_names[ 2]]))
p = p + geom_point(size=3, alpha=0.7)
p = p + facet_wrap(~distance, scales="free")
p = p + ggtitle("MDS on various distance metrics") + labs(color=col_names[1], shape=col_names[2]) 
png("05-visuals/04-beta_diversity.png", units="cm", width=50, height=50, res = 300, pointsize = 12)
p
dev.off()

## Hierarchal clustering
trans_otu <- t(otu)
bc_dist <- vegan::vegdist(trans_otu, method = "bray")
ward <- as.dendrogram(hclust(bc_dist, method = "ward.D2"))
colorCode <- c(`pre-radiotherapy` = "red", `post-radiotherapy` = "blue")
labels_colors(ward) <- colorCode[sample.data[, 1]][order.dendrogram(ward)]
png("05-visuals/05-heirarchal_clustering.png", units = "cm", width = 20, height = 15, res = 300, pointsize = 10)
plot(ward)
legend("topright", levels(sample.data[, 1]), col=c("red", "blue"), lty=1, lwd = 3)
dev.off()

## phylogenetic tree
myTaxa = names(sort(taxa_sums(expt), decreasing = TRUE)[1:50])
ex1 = prune_taxa(myTaxa, expt)
png("05-visuals/06-phylogenetics_tree.png", units = "cm", width = 20, height = 15, res = 300, pointsize = 10)
plot_tree(ex1, nodelabf=nodeplotboot(), ladderize="left", color=col_names[1], shape=col_names[2])
dev.off()
