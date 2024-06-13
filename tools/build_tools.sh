#! /bin/bash

for d in */ ; do
    cd "$d"
    ./build.sh
    cd ..
done

