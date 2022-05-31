# quantstudio
![image](https://user-images.githubusercontent.com/69192049/170927847-62db8647-e0e6-45c9-be4c-cced356e0b11.png) 


# Overview

This repository contains a simple script for converting [quantstudio3](https://www.thermofisher.com/order/catalog/product/A31665?SID=srch-srp-A31665) data into an interpretable .csv file for downstream analysis.

### How To

1) Structure 'well comments' in QuantStudio3 Design and Analysis software as follows:
    - `Annealing temperature (°C)` `primer concentration (uM)` `primer volume (uL)` `primer name` `sample volume (uL)` `Additional comments`
    - **Example:** `54`, `5`, `1`, `16S`, `8.8`, `PCR-negative control` 
    - Ensure entries are comma-separated
    - **Incomplete entries will result in mismatched output fields***

2) Export file using the export feature in QuantStudio3 software
    - As `.xls` format
    - Check content boxes for "Results" and "Amplification Data" 

3) Place file into the same directory as quantstudio.R

4) Run script 
    - Output files have the suffix: `**_output`
