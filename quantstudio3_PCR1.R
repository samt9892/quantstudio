options(java.parameters = "-Xmx16000m")            # increase java RAM allocation to avoid errors; modify based on YOUR system

#Package names
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
in.dir <- list.files(paste(wd, 'input', sep="/"), pattern = ".xls", full.names = TRUE)          #input file list



#loop over all files ----
for(i in seq_along(in.dir)) {
pcr <-  read.xlsx(in.dir[i], sheetName = "Results")
amp <- read.xlsx(in.dir[i], sheetName = "Amplification Data")

#Clean pcr data
colnames(pcr) <- pcr[42,]
pcr$filename.pcr <- pcr[[28, 2]]
pcr$run_endtime.pcr <- pcr[[29, 2]]
pcr <- pcr[-c(1:42), ]

#Clean amp data
colnames(amp) <- amp[42,]
amp$filename.pcr <- amp[[28, 2]]
amp$run_endtime.pcr <- amp[[29, 2]]
amp <- amp[-c(1:43), ]
amp <- subset(amp, Cycle == 50, select = c(`Well Position`, `Delta Rn`, `filename.pcr`, `run_endtime.pcr`))

pcr <- inner_join(amp, pcr, by = c("Well Position","filename.pcr","run_endtime.pcr"))

#Split comments field
pcr <- separate(pcr, "Comments", c("Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"),
                 sep =",\\ ", remove = F, extra = "merge", fill = "warn")

#Reorder columns
pcr <- pcr %>% 
  relocate(c("Sample Name","CT","Delta Rn","Tm1","Tm2","Tm3","Tm4","Annealing_temperature(?C)","Primer_concentration_(uM)","Primer_volume","Primer_name","Sample_volume","Additional_comments"))

#remove .xls suffix
in.dir[i] <- substr(in.dir[i],1,nchar(in.dir[i])-4) 
#Output PCR file ----
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"), row.names = FALSE)
}



#generate combined .csv file ----
# read output file paths
in.dir <- list.files(paste(wd, 'input', sep="/"), pattern = "output.csv", full.names = TRUE) 

# read combined file content
combined <- rbindlist(sapply(in.dir, fread,simplify = FALSE), idcol = 'filename', fill=TRUE)
#combined <- subset(combined, select = -c(49))               #remove duplicated filename column that mysteriously appears
combined$CT <- as.numeric(as.character(combined$CT))
  combined$CT[is.na(combined$CT)] <- 0

#combine PCR replicates (if filename=same) based on their sample number
merged <- combined %>% 
  group_by(`Sample Name`, `Primer_name`, filename.pcr) %>%
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

#append PCR pool volume
pool <- 5                                                   #set number of pools required
poolvol <- 2                                                #step volume of each pool (e.g. x, x*2, x*3, x*4 etc)

merged$pool_group <-  as.numeric(cut(merged$delta_rn, pool))        #assign pool groups based on Delta Rn           

pool_info <- merged %>%
  group_by(pool_group) %>%
  dplyr::summarise(count = n(), 
                   mean.delta_rn = mean(delta_rn), 
                   min.delta_rn = min(delta_rn),
                   max.delta_rn = max(delta_rn),
                   std_dev.delta_rn = sd(delta_rn),
                   pool_vol = poolvol/mean(delta_rn),
                   totalpoolvol = poolvol*count)
pool_info$pool_vol[pool_info$pool_vol> 5] <- 4.8              #set any volumes larger than 5 to 5 - 10ul 2nd PCR reaction vol?
pool_info$pool_vol[pool_info$pool_vol< 4] <- pool_info$pool_vol[pool_info$pool_vol< 4]*1.8              #set any volumes less than 4 to x2 
pool_info$pool_vol <- signif(pool_info$pool_vol, 2)                                                   #set significant fig to 2

#merge pool_vol into the merged file..

#to do----
#Output PCR files ----
combined_name <- paste((format(Sys.time(), "%Y-%m-%d")), "combined.csv", sep ="_")
write.csv(combined, paste(wd, "input", combined_name, sep="/"), row.names = FALSE)

merged_name <- paste((format(Sys.time(), "%Y-%m-%d")), "merged_reps.csv", sep ="_")
write.csv(merged, paste(wd, "input", merged_name, sep="/"), row.names = FALSE)

pool_name <- paste((format(Sys.time(), "%Y-%m-%d")), "pool_info.csv", sep ="_")
write.csv(pool_info, paste(wd, "input", pool_name, sep="/"), row.names = FALSE)