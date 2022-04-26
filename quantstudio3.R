library(readxl)
library(rJava) 
library(xlsx) 
library(dplyr)
options(scipen=5)                                                               #reduce decimal places

wd <- dirname(rstudioapi::getSourceEditorContext()$path)                        #get current directory
in.dir <- list.files(paste(wd), pattern = ".xls", full.names = TRUE)            #input file list



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

pcr <- inner_join(amp, pcr, by = c("Well Position", "filename.pcr", "run_endtime.pcr"))

#Reorder columns
pcr <- pcr %>% 
  relocate(c("Sample Name", "CT", "Delta Rn", "Comments", "Tm1", "Tm2", "Tm3","Tm4"))

#Output PCR file
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"))
}



