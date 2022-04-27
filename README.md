# quantstudio
Workflow for processing Applied Biosystems QuantStudio Real time PCR data into an easily interpretable file in .csv format

1) Structure well comments comments in QuantStudio3 Design and Analysis software as follows:
    - Annealing temperature (°C), primer concentration (uM), primer volume (uL), primer name, sample volume, Additional comments
    - **Example:** 54, 5, 1, 16S, 8.8, PCR-negative control 
    - Ensure entries are comma-separated
    - **Incomplete entries will result in mismatched output fields**

2) Export files using the export feature in QuantStudio3 software
    - As excel format (.xls)
    - Check content boxes for "Results" and "Amplification Data" 

3) Place files into the same directory as the script (quantstudio.R)

4) Run script 
    - Output files have the suffix: _output 
