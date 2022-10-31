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

#Loop over all PCR1 files ----
in.dir <- list.files(paste(wd, 'PCR1-xls', sep="/"), pattern = ".xls", full.names = TRUE)          #PCR1 file list

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
amp <- subset(amp, Cycle == 50, select = c(`Well Position`, `Delta Rn`, `filename`, `run_endtime`))

pcr <- inner_join(amp, pcr, by = c("Well Position","filename","run_endtime"))

#Split comments field
pcr <- separate(pcr, "Comments", c("Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"),
                 sep =",\\ ", remove = F, extra = "merge", fill = "warn")

#Reorder columns
pcr <- pcr %>% 
  relocate(c("Sample Name","CT","Delta Rn","Tm1","Tm2","Tm3","Tm4","Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"))

#remove .xls suffix
in.dir[i] <- substr(in.dir[i],1,nchar(in.dir[i])-4) 
#Output individual PCR1 .csvs ----
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"), row.names = FALSE)
}
#clean data after loop
rm(amp, pcr)



#Generate PCR1_combined files ----
# read output file paths
in.dir <- list.files(paste(wd, 'PCR1-xls', sep="/"), pattern = "output.csv", full.names = TRUE) 

# read pcr1_combined file content
pcr1_combined <- rbindlist(sapply(in.dir, fread,simplify = FALSE), idcol = 'filename_fullpath', fill=TRUE)
#pcr1_combined <- subset(pcr1_combined, select = -c(49))               #remove duplicated filename column that mysteriously appears
pcr1_combined$CT <- as.numeric(as.character(pcr1_combined$CT))
  pcr1_combined$CT[is.na(pcr1_combined$CT)] <- 0

#combine PCR replicates (if filename=same) based on their sample number
pcr1_merged <- pcr1_combined %>% 
  group_by(`Sample Name`, `Primer_name`, filename) %>%
  summarise(delta_rn = mean(`Delta Rn`), 
            CT = mean(CT), 
            Tm1 = mean(Tm1), 
            Tm2 = mean(Tm2),
            Tm3 = mean(Tm3),
            Tm4 = mean(Tm4),
            Annealing_temperature = first(`Annealing_temperature(?C)`),
            Primer_concentration = first(`Primer_concentration_(uM)`),
            Primer_volume = first(Primer_volume),
            Sample_volume = first(Sample_volume),
            Comments = first(Additional_comments))

#Calculate PCR1 pooling (based on Delta Rn) ----
pool <- 5                                                   #set number of pools required
poolvol <- 2                                                #step volume of each pool (e.g. x, x*2, x*3, x*4 etc)

pcr1_merged$pool_group <-  as.numeric(cut(pcr1_merged$delta_rn, pool))        #assign pool groups based on Delta Rn           

pcr1_pool_info <- pcr1_merged %>%
  group_by(pool_group) %>%
  dplyr::summarise(count = n(), 
                   mean.delta_rn = mean(delta_rn), 
                   min.delta_rn = min(delta_rn),
                   max.delta_rn = max(delta_rn),
                   std_dev.delta_rn = sd(delta_rn),
                   pool_vol = poolvol/mean(delta_rn),
                   totalpoolvol = poolvol*count)
pcr1_pool_info$pool_vol[pcr1_pool_info$pool_vol> 5] <- 4.8              #set any volumes larger than 5 to 5 - 10ul 2nd PCR reaction vol?
pcr1_pool_info$pool_vol[pcr1_pool_info$pool_vol< 4] <- pcr1_pool_info$pool_vol[pcr1_pool_info$pool_vol< 4]*1.8              #set any volumes less than 4 to x2 
pcr1_pool_info$pool_vol <- signif(pcr1_pool_info$pool_vol, 2)                                                   #set significant fig to 2

#merge pool_vol into the pcr1_merged file..
pcr1_merged$pool_vol <- pcr1_pool_info$pool_vol[match(pcr1_merged$pool_group, pcr1_pool_info$pool_group)]
#add _pcr1 suffix to all pcr1_merged columns
colnames(pcr1_merged) <- paste(colnames(pcr1_merged), "pcr1", sep="_")


#Output PCR1 combined, merged-reps and pool_info .csvs ----
pcr1_combined_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pcr1_combined.csv", sep ="_")
write.csv(pcr1_combined, paste(wd, "PCR1-xls", pcr1_combined_name, sep="/"), row.names = FALSE)

pcr1_merged_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pcr1_merged_reps.csv", sep ="_")
write.csv(pcr1_merged, paste(wd, "PCR1-xls", pcr1_merged_name, sep="/"), row.names = FALSE)

pool_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pcr1_pool_info.csv", sep ="_")
write.csv(pcr1_pool_info, paste(wd, "PCR1-xls", pool_name, sep="/"), row.names = FALSE)

