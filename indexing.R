#Load packages ----
options(java.parameters = "-Xmx16000m")            # increase java RAM allocation to avoid errors; modify based on YOUR system

packages <- c("readxl", "rJava", "xlsx", "dplyr", "tidyr", "data.table", "gtools")
# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


options(scipen = 5)                                                                               #reduce decimal places
wd <- dirname(rstudioapi::getSourceEditorContext()$path)                                        #get current directory

#Read in data ----
in.dir <- list.files(paste(wd, 'PCR2-xls/output', sep = "/"), pattern = "list_for_pooling.csv", full.names = TRUE)

samples <- rbindlist(sapply(in.dir, fread,simplify = FALSE), idcol = 'filename_fullpath', fill = TRUE)
# Remove spaces in a specific column
samples$forward_tag_pcr2 <- gsub("\\s+", "", samples$forward_tag_pcr2)
samples$reverse_tag_pcr2 <- gsub("\\s+", "", samples$reverse_tag_pcr2)


#read in index metadata
indexes <- read.xlsx(paste(wd, 'index_metadata.xlsx', sep = "/"),1)
indexes$Name <- toupper(indexes$Name)                                    #change index$Name characters to uppercase if needed

#add index sequences to the samples ----
# Find the matching indexes
matching_indexes <- match(samples$forward_tag_pcr2, indexes$Name)
# Add the forward_tag_sequence column to samples
samples$forward_tag_sequence <- indexes$index_sequence[matching_indexes]

matching_indexes <- match(samples$reverse_tag_pcr2, indexes$Name)
# Add the forward_tag_sequence column to samples
samples$reverse_tag_sequence <- indexes$index_sequence[matching_indexes]

write.csv(samples, paste(wd, "final_metadata_output.csv", sep = "/"), row.names = F)
