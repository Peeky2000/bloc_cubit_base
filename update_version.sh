#!/bin/bash

new_version="$1+$(expr $2 + 1)"
i=1
    while read line; do

    if [[ $line == *"version: "* ]]; then
        sed -i '' "s/$line/version: $new_version/g" $PWD/pubspec.yaml
        # echo "sed -i '' 's/$line/a=999/g' $file"
    fi
    i=$((i+1))
    done < $PWD/pubspec.yaml