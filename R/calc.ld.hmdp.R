# Script for estimating LD decay in the Hybrid Mouse Diversity Panel.
# These calculations use 130,908 SNPs genotyped on chromosomes 1-19
# for 251 strains. The data were downloaded from
# http://mouse.cs.ucla.edu/mousehapmap. To simplify the analysis,
# heterozygous genotypes are set to missing. The --r2 command in
# PLINK v1.9beta3.33 is used to compute the r^2 measure of LD (see
# Pritchard and Przeworski, 2001) based on maximum-likelihood
# estimates of the haplotype frequencies.
library(data.table)

# SCRIPT PARAMETERS
# -----------------
# Which chromosome to analyze.
which.chr <- 1

# PLINK .bed/.bim/.fam files containing the genotype data.
geno.file <- "hmdp"

# These are the bins used for the LD calculations.
bins <- seq(0,5e6,1e5)

# Initialize the pseudorandom number generator.
set.seed(1)

# LOAD SNP INFO
# -------------
cat("Loading SNP data.\n")
map        <- read.table("hmdp.bim",stringsAsFactors = FALSE)
names(map) <- c("chr","id","dist","pos","A1","A2")
map        <- subset(map,chr == which.chr)
cat("Loaded SNP data for",nrow(map),"markers.\n")

# LOAD SNP ALLELE FREQUENCIES
# ---------------------------
cat("Loading SNP allele frequencies")
system("mkdir -p out_plink")
system(sprintf("plink2 --bfile %s --freq --chr %d --out out_plink/hmdp",
               geno.file,which.chr))
out <- read.table("out_plink/hmdp.frq",header = TRUE,stringsAsFactors = FALSE)
map <- cbind(map,data.frame(maf = out$MAF))
rm(out)

# Sample LD estimates within each bin from this many randomly selected
# SNP pairs.
ns <- round(nrow(map)/10)

# COMPUTE LD USING PLINK
# ----------------------
ld.matrix <- vector("list",19)
cat("Computing LD using PLINK: ")
out.file <- sprintf("out_plink/chr%d",which.chr)
system(sprintf("plink2 --bfile %s --chr %d --r2 square --out %s",
               geno.file,which.chr,out.file),ignore.stdout = FALSE)
out <- fread(paste0(out.file,".ld"),verbose = TRUE,showProgress = TRUE)
class(out)    <- "data.frame"
out           <- as.matrix(out)
rownames(out) <- map$id
colnames(out) <- map$id
ld.matrix[[which.chr]] <- out
cat("\n")
rm(out.file,out)

# SAMPLE LD WITHIN BASE-PAIR INTERVALS
# ------------------------------------
source("sample.ld.R")

# SAVE RESULTS TO FILE
# --------------------
cat("Saving results to file.\n")
save(list = c("bins","ld","map"),
     file = paste0("LDdecay.HMDP.chr",which.chr,".RData"))
