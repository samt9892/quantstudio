#Package names
packages <- c("readxl", "rJava", "xlsx", "dplyr", "tidyr")
# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


options(scipen=5)                                                               #reduce decimal places
wd <- dirname(rstudioapi::getSourceEditorContext()$path)                        #get current directory
in.dir <- list.files(paste(wd, 'input', sep="/"), pattern = ".xls", full.names = TRUE)            #input file list



#loop over all files
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
#Output PCR file
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"), row.names = FALSE)
}


#remove .xls suffix
#in.dir <- substr(in.dir,1,nchar(in.dir)-4) 
#Output PCR file
#for(i in seq_along(in.dir)) {
  #write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"), row.names = FALSE)
#}