#!/bin/bash
#This script will softlink files with a certain naming convention.

for i in {1..2} {5..7}
do
idx=$i
fmt_idx=$(printf "%03d" ${idx})
myFileIN="TS_${fmt_idx}/TS_${fmt_idx}_bin4.rec"
myFileOUT="TS_${fmt_idx}_bin4.rec"
myDir="$(pwd -P)"

ln -sf "$myDir/$myFileIN" "$myDir/$myFileOUT"

done
