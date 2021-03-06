##############################################################################
###################### Data filtering for DADA2 results ######################
##############################################################################


# Author: Lucy Goodyear (leg19@ic.ac.uk)
# Version: 0.0.1

# clear worksapce
rm(list=ls())


################################## Set up ####################################


# on local computer: store all console output to an output file
#sink("DADA2_data_filtering_output.log", type=c("output", "message"))

# import arguments to run script on specific country data
#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE) # setup to accept arguments from command line
# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied in the form of an R-script containing the following arguments: 
       1) run = name of run followed by /
       2) country = name of country
       3) root_path = path until directory above run folowed by /
       4) metadata_path = path to metadata csv
       5) path_in = path to input data
       6) path_out = path to output phyloseq object results to")
}
# load arguments into script
source(args)
# print arguments as check
print("Arguments:")
print(paste0("run: ", run))
print(paste0("country: ", country))
print(paste0("root_path: ", root_path))
print(paste0("metadata_path: ", metadata_path))
print(paste0("path_in: ", path_in))
print(paste0("path_out: ", path_out))

# load packages
print("Loading required packages...")
library(phyloseq)
library(dplyr)


################################# Load data #####################################


print("Loading data...")

# load taxa data
tax <- read.table(paste0(path_in, "Taxa_Table.txt"), 
                  stringsAsFactors = F,
                  header = T)
# rename columns
colnames(tax) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")

# load abundance data
seqtab <- read.table(paste0(path_in, "Abun_Table_sample_row.txt"), 
                     stringsAsFactors = F,
                     header = T)

# load plate data
plates <- read.csv(paste0(root_path, run, "Plate_Data.csv"), 
                   stringsAsFactor=F, 
                   header=T)

# load metadata
metadata <- read.csv(metadata_path,
                     stringsAsFactor=F, 
                     header=T)

# add column for Bd +ve/-ve to metadata
metadata$Bd <- NA
for (i in (1:nrow(metadata))){
  if (is.na(metadata$Bd_GE[i])){
    metadata$Bd[i] <- NA
  }
  else {
    if (metadata$Bd_GE[i] >= 0.1){
    metadata$Bd[i] <- 1
    } 
    if (metadata$Bd_GE[i] < 0.1){
    metadata$Bd[i] <- 0
    }
  }
}

# set as factor for plotting
metadata$Bd <- as.factor(metadata$Bd)


######################### remove PosC, Mocks and NC ###########################


#################### Set up


print("Performing set up...")

# change sample names in plate data to match processed data format
plates$Sample_Name <- gsub("_", "-", plates$Sample_Name)
# country specific requirements: uncomment as required
## Vietnam
#plates$Sample_Name <- gsub("-", "", plates$Sample_Name)
## Pyrenees
#plates$Sample_Name <- gsub("mock1-A", "mock1", plates$Sample_Name)
#plates$Sample_Name <- gsub("NC-PCR1-A", "NC-PCR1", plates$Sample_Name)
#plates$Sample_Name <- gsub("NC-swab1-A", "NC-swab1", plates$Sample_Name)
#plates$Sample_Name <- gsub("posC1-A", "posC1", plates$Sample_Name)
## Costa Rica
#plates$Sample_Name <- gsub("2016", "", plates$Sample_Name)
#plates$Sample_Name <- gsub("-cr", "CR", plates$Sample_Name)

# set rownames of taxonomy table to match column names of abundance table
rownames(tax) <- colnames(seqtab)

# transpose abundance table
seqtab_t <- as.data.frame(t(seqtab))

# PosC and Mock seem to be swapped for TW17
# plate 1 (Taiwan1a, Taiwan1b)
#seqtab_t <- seqtab_t %>% rename(mock1 = "posC1", posC1 = "mock1")
# plate 2 (Taiwan2)
#seqtab_t <- seqtab_t %>% rename(mock2 = "posC2", posC2 = "mock2")
# plate 3 (Taiwan3)
#seqtab_t <- seqtab_t %>% rename(mock3 = "posC3", posC3 = "mock3")
# transpose back
#seqtab <- as.data.frame(t(seqtab_t))

# subset taxonomy table
species_by_seq <- as.data.frame(cbind(rownames(tax), tax$Genus, tax$Species))
names(species_by_seq) <- c("Sequence", "Genus", "Species")

# merge subsetted taxa table and the abundance table
species_abun <- merge(species_by_seq, seqtab_t, by.x = "Sequence", by.y = "row.names")

# create vector of plate numbers that the country was present on
plate_nos <- c()
for (samp in 1:nrow(plates)){
  if (plates$Origin[samp] == country) {
    plate_nos <- c(plate_nos, plates$Plate[samp])
  } 
  plate_nos <- unique(plate_nos)
}

# Pyrenees, Taiwan1a, Taiwan1b
#plate_nos <- 1
# Taiwan2
#plate_nos <- 2
# Taiwan3
#plate_nos <- 3


######################### PosC


print("Locating posC ASVs...")

# subset merged data frame to include only positive controls
posc <- cbind(species_abun$Sequence, paste(species_abun$Genus, species_abun$Species),species_abun[grep("posC",names(species_abun))])
# rename columns
names(posc)[1:2] <- c("Sequence", "Genus_Species")

# find posC species
posc_ls <- c()
for (plate in plate_nos) {
  assign(paste0("poscspec", plate), as.character(posc$Genus_Species[posc[[paste0("posC", plate)]] > 1000]))
  posc_ls <- c(posc_ls, get(paste0("poscspec", plate)))
}

# find unique posC species
uniqposcspec <- unique(posc_ls)
print(paste("PosC species is", uniqposcspec))

# subset sequences that are the same as the species of posC and count them
posc_seqs <- as.character(posc$Sequence[posc$Genus_Species %in% unique(uniqposcspec)])
print(paste0("Number of ASVs that are same as posC species: ", length(posc_seqs)))

# remove PosC sequences
seqtab <- seqtab[,!names(seqtab) %in% posc_seqs]


###################### Mocks


print("Locating mock ASVs...")

# subset merged data frame to include only positive controls
mocks <- cbind(species_abun$Sequence, paste(species_abun$Genus, species_abun$Species),species_abun[grep("mock",names(species_abun))])
# rename columns
names(mocks)[1:2] <- c("Sequence", "Genus_Species")

# find mock species
mock_ls <- c()
for (plate in plate_nos) {
  assign(paste0("mockspec", plate), as.character(mocks$Genus_Species[mocks[[paste0("mock", plate)]] > 1000]))
  mock_ls <- c(mock_ls, get(paste0("mockspec", plate)))
}

# find unique mock species
uniqmockspec <- unique(mock_ls)
print(paste("Mock species are", uniqmockspec))

# subset sequences that are the same as the species of the mocks and count them
mock_seqs <- as.character(mocks$Sequence[mocks$Genus_Species %in% unique(uniqmockspec)])
print(paste0("Number of ASVs that are mock species: ", length(mock_seqs)))

# remove mock sequences
seqtab <- seqtab[,!names(seqtab) %in% mock_seqs]
# remove mocks from samples
seqtab <- seqtab[!rownames(seqtab) %in% c("mock1", "mock2", "mock3", "mock4"),]


##################### Controls


print("Removing sequences found in negative controls...")

# create vector of negative control sample names
NCs <- c()
for (samp in 1:nrow(plates)){
  if (grepl("NC", plates$Origin[samp])) {NCs <- c(NCs, plates$Sample_Name[samp])} 
}

# define function to remove posC and NC reads from samples by plate
# returns a dataframe containing samples from the specifed plate, in the same form as df_abun 
filter_controls <- function(df_abun, df_plates, plate_no) {
  
  # subset by plate number
  plate <- df_abun[,names(df_abun) %in% c(df_plates$Sample_Name[df_plates$Plate == plate_no])]
  # create new column summing NC and PosC reads per sample
  if (ncol(plate[,colnames(plate) %in% NCs, drop=FALSE]) == 0) { # check to see if there are any negative controls in the plate
    plate$sum <- plate[,(paste0("posC", plate_no))]
  } else {
    plate$sum <- rowSums(plate[,c(colnames(plate[,colnames(plate) %in% NCs, drop=FALSE]), paste0("posC", plate_no))])
  }
  
  # print summary statements
  print(paste0("Number of samples in plate ", plate_no, ": ", length(names(plate))-1)) # count samples - sum column
  print(paste0("Number of ASVs with NC/PosC reads not equal to 0: ", length(which(plate$sum != 0)))) # count ASVs with NC + posC reads not equal to 0
  print(paste0("Number of NC and posC reads overall before: ", sum(plate$sum))) # sum overall NC + posC reads
  
  # remove number of reads in NC + posC ASVs from corresponding ASVs for each sample
  platex <- as.data.frame(t(apply(plate, 1, function(x) x - x["sum"])))
  # set any negative values (create by the above) to 0
  platex[platex < 0] <- 0
  
  # print a check statement
  print(paste0("CHECK. Number of NC and posC reads overall after: ", sum(platex$sum), " (should be 0)")) # should be 0
  # remove sum column
  platex <- subset(platex, select=-sum)
  
  return(platex)
}

# transpose filtered abundance table
seqtab_t <- as.data.frame(t(seqtab))
# run the function on all plates
seqtab_t_filtered <- data.frame(row.names=row.names(seqtab_t))
for (plate in plate_nos) {
  assign(paste0("plate", plate), filter_controls(seqtab_t, plates, plate))
  # combine the plates into one dataframe
  seqtab_t_filtered <- cbind(seqtab_t_filtered, get(paste0("plate", plate)))
}

# remove empty all samples (including posC and NC) from data frame
# sum abundances by sample
seqtab_t_filtered <- rbind(seqtab_t_filtered, apply(seqtab_t_filtered, 2, sum))
# transpose dataframe
seqtab_filtered <- as.data.frame(t(seqtab_t_filtered))
# count how many samples have no reads
print(paste0("Number of sample with no reads after filtering: ", length(which(seqtab_filtered[,ncol(seqtab_filtered)] == 0))))

print("Removing empty samples...")
# save empty samples as a vector
to_remove <- which(seqtab_filtered[,ncol(seqtab_filtered)] == 0)
# remove empty samples from dataframe
seqtab_filtered <- as.data.frame(seqtab_filtered[!rownames(seqtab_filtered) %in% names(to_remove),])
# remove sum column
seqtab_filtered <- seqtab_filtered[,-ncol(seqtab_filtered)]


######################### Tidy up


# remove empty ASVs
print("Removing empty ASVs...")

# subset by non-empty ASVs
# sum abundances by ASV
seqtab_filtered <- rbind(seqtab_filtered, apply(seqtab_filtered, 2, sum))
# subset by non-empty ASVs
seqtab_filtered <- seqtab_filtered[,which(seqtab_filtered[nrow(seqtab_filtered),] != 0)]
# remove sum row
seqtab_filtered <- seqtab_filtered[c(1:(nrow(seqtab_filtered)-1)),]

# subset taxa table to include only the non-empty ASV assignments
tax <- tax[which(rownames(tax) %in% names(seqtab_filtered)),]


################################ create phyloseq object ################################


print("Saving to phyloseq object...")

# transform to matrix
seqtab_mat <- as.matrix(seqtab_filtered)

tax_mat <- as.matrix(tax) # required to create phyloseq object

## Ecuador sample name change - comment out for all other runs
#metadata$MiSeqCode <- gsub("^", "X", metadata$MiSeqCode)

# create list of samples with no MiSeq code
rm_id <- c()
for (id in 1:nrow(metadata)){
  if (metadata$MiSeqCode[id] == "") {
    rm_id <- c(rm_id, id)
  }
}
# remove samples with no MiSeq code
if (!is.null(rm_id)) {
  metadata <- metadata[-c(rm_id),]
}

# rename Order, Family and Genus_Species columns in metadata 
# (so no confusion occurs between amphibian taxa and fungal taxa)
metadata <- rename(metadata ,c('A_Order' = 'Order', 
                               'A_Family' = 'Family',
                               'A_Genus_Species' = 'Genus_Species'))

# set rownames of metadata to be MiSeq Code
rownames(metadata) <- metadata$MiSeqCode

# use the below command to solve the error:
# "Error in validObject(.Object) : invalid class “phyloseq” object: 
# Component sample names do not match.
# Try sample_names()"
# filling in the required substitution
#rownames(seqtab_mat) <- gsub("X", "", rownames(seqtab_mat))

require(phyloseq)
dada2 <- phyloseq(tax_table(tax_mat), 
                  otu_table(seqtab_mat, taxa_are_rows = FALSE), 
                  sample_data(metadata))

# add shannon alpha diversity column to metadata
shannon_dada2 <- estimate_richness(dada2, split = TRUE, measures = "Shannon")
sample_data(dada2)$Alpha_Shannon <- as.numeric(shannon_dada2[,1])

# save with raw sequences for phylogenetic tree script
saveRDS(dada2,paste0(path_out,"physeqob_DADA2_tree.rds"))

# save sequences to refseqs slot and rename ASVs for convenience
asv_seqs <- Biostrings::DNAStringSet(taxa_names(dada2))
names(asv_seqs) <- taxa_names(dada2)
dada2 <- merge_phyloseq(dada2, asv_seqs)
taxa_names(dada2) <- paste0("ASV", seq(ntaxa(dada2)))

# print out phyloseq object to screen
dada2

# save phyloseq object to be imported into analysis scripts
saveRDS(dada2,paste0(path_out,"physeqob_DADA2.rds"))

print("Script completed")


## end of script

