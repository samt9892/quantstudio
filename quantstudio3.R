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

#Clean pcr data
colnames(pcr) <- pcr[42,]
pcr$filename.pcr <- pcr[[28, 2]]
pcr$run_endtime.pcr <- pcr[[29, 2]]
pcr <- pcr[-c(1:42), ]

#Reorder columns
pcr <- pcr %>% 
  relocate(c("Sample Name", "CT", "Comments", "Tm1", "Tm2", "Tm3","Tm4"))

#Output PCR file
write.csv(pcr, paste(in.dir[i], "output.csv", sep = "_"))
}



