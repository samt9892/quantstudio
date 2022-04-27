# quantstudio
Workflow for processing Applied Biosystems QuantStudio Real time PCR data into an easily interpretable file in .csv format

1) Structure sample comments in QuantStudio3 software as follows:
    - Annealing temperature (°C), primer concentration (uM), primer volume (uL), primer name, sample volume, Additional comments
    - **Example:** 54, 5, 1, 16S, 8.8, PCR-negative control 
    - **Incomplete entries will result in mismatched output fields**

2) export files using the export feature in QuantStudio3 software
    - As excel format (.xls)
    - All data types selected

3) place files into the same directory as the script (quantstudio.R)

4) Run script 
    - Output files have the suffix: _output 
