#! /bin/bash

EXTRACTBIT3=./compress/extractbit3
FILEDIFF=./compress/filediff
RLE=./compress/rle

inputfile=$1

filename="${inputfile%.*}"
extension="${inputfile##*.}"

outputfile="$inputfile.rle"

if [[ "$extension" = "tilemap" ]] || [[ "$extension" = "attrmap" ]]; then
    echo "Copying $inputfile to $outputfile"
    cp -f $inputfile $outputfile
    if [[ "$extension" = "attrmap" ]]; then
        echo "Compressing $outputfile with extractbit3"
        $EXTRACTBIT3 $outputfile $outputfile
    fi
    echo "Compressing $outputfile with filediff"
    $FILEDIFF $outputfile $outputfile
    echo "Compressing $outputfile with rle"
    $RLE -e $outputfile
else
    echo "ERROR: Input file extension must be .tilemap or .attrmap"
fi

