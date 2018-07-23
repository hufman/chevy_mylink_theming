#!/bin/bash

function hide_layers {
  test -n "$pathname" || pathname="$1"
  test -n "$layername" || layername="$2"
  cat "$pathname" | xmlstarlet ed \
    -N svg="http://www.w3.org/2000/svg" \
    -i "/svg:svg/svg:g[not(@style)]" -t attr -n 'style' -v '' \
    -u "/svg:svg/svg:g[starts-with(@id, 'Original_')]/@style" -v 'display:none' \
    -u "/svg:svg/svg:g[starts-with(@id, 'New_')]/@style" -v 'display:none' \
    -u "/svg:svg/svg:g[@id='New_$layername']/@style" -v 'display:inline'
}

find . -name '*.svg' | while read path; do
  grep -q "StillImage" "$path" || continue

  layers=$(cat "$path" | xmlstarlet sel \
    -N svg="http://www.w3.org/2000/svg" \
    -t -v "/svg:svg/svg:g[starts-with(@id, 'New_')]/@id"
  )
  for layer in $layers; do
    layername=$(echo "$layer" | sed 's|New_||')
    
    if grep -q "xlink:href.*bmp" "$path"; then
      bmppath=$(dirname "$path")/"$layername".bmp
      convert <(hide_layers "$path" "$layername") -type Palette -colors 256 BMP3:"$bmppath"
    elif grep -q "xlink:href.*png" "$path"; then
      pngpath=$(dirname "$path")/"$layername".png
      convert <(hide_layers "$path" "$layername") "$pngpath"
    fi
  done
done
