#!/bin/bash

MOD2GBT=./mod2gbt/mod2gbt

inputfile=$1

filename="${inputfile%.*}"
extension="${inputfile##*.}"

outputfile="filename"

if [[ "$extension" = "mod" ]]; then
    echo "Converting $inputfile to $outputfile.asm"
    $MOD2GBT $inputfile $outputfile
else
    echo "ERROR: Input file extension must be .mod"
fi

