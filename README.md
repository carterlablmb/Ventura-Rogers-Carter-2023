# Ventura-Rogers-Carter-2023
This repository contains scripts used to export coordinates from IMOD models to Dynamo 'filament with torsion' models and for determining filament polarities from multireference alignment classification results.


1. Workflow for export of IMOD model coordinates into Dynamo 'filament with torsion' for subtomgram averaging

Requirements:
- Dynamo version 1.1.2 (or similar)
- MATLAB version 2019 (or similar)
- IMOD version 4.10.32 (or similar)

- a folder with tomograms softlinked. Convention: TS_01_bin4.rec, TS_02_bin4.rec, etc. Tomograms can be softlinked into the main folder using the quick_softlink_TS.sh bash script.
- a folder with IMOD models: IMODmods. Model naming convention: TS_01_bin4.mod, TS_02_bin4.mod


A) Run the Imod_Model_to_Dynamo_Filament_Model.sh script with instructions given in the script.

B) Run the tomoidx_script.sh (This is only needed if you want to convert the dynamo table into a motive list (MOTL) for visualization in chimera.

C) Open matlab and activate Dynamo. Generate a new Dynamo catalogue in MATLAB:
dcm -create cataogue_name -vll vll_file_name

D) Open the matlab_printer file. Copy everything and paste it into the MATLAB command line. This is not very elegant but will add all the filament models and link them to the catalogue.

E) Check if the models have been correctly linked:
dmodels catalogue_name

F) Proceed with cropping particles (f. e. in the Dynamo GUI) and alignment projects in Dynamo. To transition to Relion 3, you can for example use the dynamo2m package (https://github.com/alisterburt/dynamo2m).





2. Workflow for filament polarity determination
Requirements:
- Dynamo version 1.1.2 (or similar)
- MATLAB version 2019 (or similar)

A) Perform one round of multireference alignment to a minus and plus end oriented filament reference in Dynamo. If you only want to find out the polarity of homogeneous filaments, 2 references with opposite polarity are enough. If you also want to classify other features (f. e. microtubule protofilament numbers) more references are needed. I used 8 references (12, 13, 14, 15 protofilaments, each plus and minus). 

B) In MATLAB, run the script 'LuminalFilamentPol_Assessment_script.m' (for MRA with 2 references) or 'Microtubule_PFnumber_Polarity_Assessment_script.m' (for 8 references) to analyse the distribution of particle classes in each filament and to assign the filament models to a polarity.

