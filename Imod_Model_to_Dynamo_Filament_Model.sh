#!/bin/bash
#This script will extract the co-ordinates of a model from imod so it can be imported into dynamo. It will create a txt file with all co-ordinates and print matlab command to import these models into a dynamo catalogue.
#This script will extract all contours from a single object which you should specify. We use object 1 for all microtubules with 1 microtubule per contour.
#This script will loop over all models in folder and list their associated tomogram (model name shoulh start with tomogram name)
#Model names must start with TS_??
#It will generate a .txt file ("matlab_printer") with commands for importing these models into matlab and another with a volume list to import these tomograms into matlab
#HF 10/2019, CV updated 09/2021

#############################################################################################################################################

#Output description#
#modinfo.txt - model info from imod. Contains description of objects and models in .mod file.
#modLIST.txt - list of models to export with number of contours for specified object.
#For each model:
##$modout.txt - co-ordinates of all points in model, created by model2point. Will extract desired points from this with correct object and contour numbers.
#For each contour:
##$dModName.txt - x,y,z co-ordinates of contour from specified object for input to dynamo
#mP_out - text file containing matlab commands to create all models and link to catalogue in dynamo


#############################################################################################################################################

# Usage

# This script runs on IMOD 4.10.32. 
# Adjust the FILE_INPUTS parameters
# Run the script in a bash terminal. Then, generate a dynamo catalogue in MATLAB with the 'catalogue_name' and 'tomograms.vll' name given in this script: 
# dcm -create  'catalogue_name' -vll 'tomograms.vll'
# Then, copy and paste the 'matlabPrinter.txt' into the matlab command line. This will add the models to the catalogue.
# Check if the models have been added to the correct volumes:
# dcmodels 'catalogue_name'
# Proceed with the generation of a Dynamo cropping table in MATLAB/ Dynamo. For example in the Dynamo GUI:
# dcm -c 'catalogue_name'


########FILE_INPUTS######
#directory for all models
modFolder="IMODmods"
#object number to extract. This refers to the IMOD model object number.
obj="1"
#tomogram suffix that you want to import(everything after TS_??), for example "_bin4.rec". Naming convention for tomograms: f.e. TS_001_bin4.rec
tomoSuffix="_bin4.rec"

########DYNAMO_INPUTS######
#catalogue name
cat='catalogue_name'
#starting volume number in catalogue (0 if using vol 1)
vol=0
#desired name for matlabPrinter output
mP_out='matlabPrinter.txt'
#desired name for volumelist output
vll_out='tomograms.vll'
#edit matlab printer depending on desired model in dynamo. In particular adjust: subunits_dphi (rotation in degrees applied to consecutive particles along the filament axis), subunits_dz (particle distance along the filament axis in pixels) .
function matlabPrinter {
	echo "%" >> $mP_out
	echo $dModName" = dmodels.filamentWithTorsion();" >> $mP_out
	echo "myPoints = dread('"$dModName".txt');" >> $mP_out
	echo $dModName".addPoint(myPoints);" >> $mP_out
	echo $dModName".subunits_dphi = 30;" >> $mP_out
	echo $dModName".subunits_dz   = 6.77;" >> $mP_out
	echo $dModName".backbone_interval = 10;" >> $mP_out
	echo $dModName".backboneUpdate();" >> $mP_out
	echo $dModName".updateCrop();" >> $mP_out
	echo $dModName".name = '"$dModName"';" >> $mP_out
	echo $dModName".linkCatalogue('"$cat"','i',""$vol,'s',1);" >> $mP_out
	echo "%%" >> $mP_out
}

function vllPrinter {
	echo "" >> $vll_out
	echo $tomoName$tomoSuffix >> $vll_out
	echo "* index = "$vol >> $vll_out
	echo "" >> $vll_out
}


##########################

#Get model info for all models in folder
imodinfo -f modinfo.txt $modFolder/*.mod

#print desired object and contours
grep -e 'mod' -e ",$obj,0" modinfo.txt | sed 's/^.*TS/TS/' | sed 's/.*#//' | cut -f1 -d, > modLIST.txt
#sed; s for substitute match (with nothing so delete from line). 's/.*#//' will remove everything before a # match.'s/^.*TS/TS/' will match any text before TS and replace with TS. ^[ \t]* will match any space at beginning of line, [ \t]*$ for end of line
#cut will only keep the first field after the deliminator ','
#grep; -e for pattern match. -A to print 2 lines after match

#Clean up before matlabPrinter
rm $mP_out
rm $vll_out

while IFS= read -r line; do
	if [[ $line == "TS"* ]]; then
		mod=$line
		vol=$((vol+1))
		echo "New mod $mod. New vol $vol"
		modout=$(echo "$mod" | sed 's/.mod//')
		tomoName=$(echo "$mod" | awk -F '_' '{print $1"_"$2}')
		#Print tomogram volume list to .vll
		vllPrinter

		#convert imod model to text fie containing x,y,z co-ordinates of points, -ob to list objects and contours
		model2point -i $modFolder/$mod -ou $modout.txt -ob
	else
		n=$line
		cont=$(printf "%02d" ${n})
		#will iterate over each contour in file
		dModName=$tomoName"_obj_"$obj"_cont_"$cont
		echo "Printing: $mod $obj $cont $vol"
		#extract info for each contour in specified object, save x,y,z in text file
		awk -v val=$obj '$1 == val' $modout.txt | awk -v val=$cont '$2 == val' | awk '{print $3, $4, $5;}' > $dModName.txt

		#Print commands to import models into matlab
		matlabPrinter
	fi
done < modLIST.txt

echo "~~~~~~~~~~~~"
echo "Commands in $mP_out"
echo "Dynamo vll in $vll_out"
tomoN=$(cat modLIST.txt | grep TS | wc -l)
echo "Tomograms processed: $tomoN"
modN=$(cat modLIST.txt | grep -v TS | wc -l)
echo "Number of models: $modN"

