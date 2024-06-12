#! /bin/bash

inputfile=$1
filename="${inputfile%.*}"
tilemap="$filename.tilemap"
attrmap="$filename.attrmap"

echo "Converting $inputfile to $tilemap and $attrmap"

head -c 360 $inputfile > $tilemap
tail -c 360 $inputfile > $attrmap
