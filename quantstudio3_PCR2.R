#Load packages ----
options(java.parameters = "-Xmx16000m")            # increase java RAM allocation to avoid errors; modify based on YOUR system

packages <- c("readxl", "rJava", "xlsx", "dplyr", "tidyr", "data.table")
# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


options(scipen=5)                                                                               #reduce decimal places
wd <- dirname(rstudioapi::getSourceEditorContext()$path)                                        #get current directory
#delete old outputs and build new output directory
unlink(paste(wd, "PCR2-xls", "output", sep = "/"), recursive=TRUE)                              #delete output directory
dir.create(paste(wd, "PCR2-xls", "output", sep = "/"))                                          #make output directory


#Loop over all PCR2 files ----
in.dir <- list.files(paste(wd, 'PCR2-xls', sep="/"), pattern = ".xls", full.names = TRUE)          #PCR2 file list

for(i in seq_along(in.dir)) {
pcr <-  read.xlsx(in.dir[i], sheetName = "Results")
amp <- read.xlsx(in.dir[i], sheetName = "Amplification Data")

#Clean pcr data
colnames(pcr) <- pcr[42,]
pcr$filename <- pcr[[28, 2]]
pcr$run_endtime <- pcr[[29, 2]]
pcr <- pcr[-c(1:42), ]

#Clean amp data
colnames(amp) <- amp[42,]
amp$filename <- amp[[28, 2]]
amp$run_endtime <- amp[[29, 2]]
amp <- amp[-c(1:43), ]
amp <- subset(amp, Cycle == 10, select = c(`Well Position`, `Delta Rn`, `filename`, `run_endtime`))

pcr <- inner_join(amp, pcr, by = c("Well Position","filename","run_endtime"))

#Split comments field
pcr <- separate(pcr, "Comments", c("Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"),
                 sep =",\\ ", remove = F, extra = "merge", fill = "warn")
#Split Forward and Reverse primers from 2nd round
pcr <- separate(pcr, "Primer_name", c("forward_tag", "reverse_tag"),
                sep="\\+", remove = F, extra = "merge", fill = "warn")
#Extract primer name from first round
pcr <- separate(pcr, "Additional_comments", c("firstround_primer_name", "Comments2"),
                sep="_", remove = F, extra = "merge", fill = "warn")

#Reorder columns
pcr <- pcr %>% 
  relocate(c("Sample Name","CT","Delta Rn","Tm1","Tm2","Tm3","Tm4","Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"))

#remove .xls suffix
in.dir[i] <- substr(in.dir[i],1,nchar(in.dir[i])-4) 
#Output individual PCR2 .csvs ----
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"), row.names = FALSE)
}
#clean data after loop
rm(amp, pcr)



#Generate PCR2_combined files ----
# read output file paths
in.dir <- list.files(paste(wd, 'PCR2-xls', sep="/"), pattern = "output.csv", full.names = TRUE) 

# read pcr2_combined file content
pcr2_combined <- rbindlist(sapply(in.dir, fread,simplify = FALSE), idcol = 'filename_fullpath', fill=TRUE)
#pcr2_combined <- subset(pcr2_combined, select = -c(49))               #remove duplicated filename column that mysteriously appears
pcr2_combined$CT <- as.numeric(as.character(pcr2_combined$CT))
  pcr2_combined$CT[is.na(pcr2_combined$CT)] <- 0

#combine PCR replicates (if filename=same) based on their sample number
pcr2_merged <- pcr2_combined %>% 
  group_by(`Sample Name`, `Primer_name`, filename, `firstround_primer_name`) %>%
  summarise(delta_rn = mean(`Delta Rn`), 
            CT = mean(CT), 
            Tm1 = mean(Tm1), 
            Tm2 = mean(Tm2),
            Tm3 = mean(Tm3),
            Tm4 = mean(Tm4),
            Well_position = first(`Well Position`),
            forward_tag = first(forward_tag),
            reverse_tag = first(reverse_tag),
            Annealing_temperature = first(`Annealing_temperature(?C)`),
            Primer_concentration = first(`Primer_concentration_(uM)`),
            Primer_volume = first(Primer_volume),
            Sample_volume = first(Sample_volume),
            Comments = first(Additional_comments))

#add _pcr2 suffix to all pcr2_merged columns
colnames(pcr2_merged) <- paste(colnames(pcr2_merged), "pcr2", sep="_")

#Combine PCR2_merged with PCR1_merged ----
#read in PCR1
pcr1_merged <- list.files(paste(wd, 'PCR1-xls', sep="/"), pattern = "pcr1_merged_reps.csv", full.names = TRUE) 
pcr1_merged <- read.csv(pcr1_merged[1])
#merge PCR1 + 2
both_merged <- right_join(pcr1_merged, pcr2_merged, by = c("Sample.Name_pcr1" = "Sample Name_pcr2", "Primer_name_pcr1" = "firstround_primer_name_pcr2"))
#move columns with pooling info to the front
both_merged <- both_merged %>% relocate(c(pool_group_pcr1, pool_vol_pcr1, Well_position_pcr2), .after = Primer_name_pcr1)

#Output pcr2 combined, merged-reps and pool_info .csvs ----
pcr2_combined_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pcr2_combined.csv", sep ="_")
write.csv(pcr2_combined, paste(wd, "pcr2-xls", pcr2_combined_name, sep="/"), row.names = FALSE)

pcr2_merged_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pcr2_merged_reps.csv", sep ="_")
write.csv(pcr2_merged, paste(wd, "pcr2-xls", pcr2_merged_name, sep="/"), row.names = FALSE)

