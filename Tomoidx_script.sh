#!/bin/bash

# This script generates a list of the tomograms in the dynamo catalogue to assign them to the index.
# CV updated 03/2023

###################################################################################

# Usage of the script

# Change the "catalogue.vll" file name to the dynamo catalogue .vll file generated with the "Imod_Model_to_Dynamo_Filament_Model.sh" script
# Change the tomogram naming convention by adjusting the 'sed' terms. Our naming convention is TS_01_bin4.rec.

counter=1
while IFS= read -r line; do
	if [[ $line == "TS_"* ]]; then
		echo -e "$counter $line" | sed 's/TS_//' | sed 's/_bin4.rec//' >> tomoidx_tomoname.txt
		(( counter++))
	fi
done < catalogue.vll
