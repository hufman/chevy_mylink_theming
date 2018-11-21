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
      [ "$bmppath" -nt "$path" ] && continue	# skip files that are newer
      #convert -background '#910101' -transparent-color '#910101' <(hide_layers "$path" "$layername") gif:"$bmppath".gif
      size=$(xmlstarlet sel -N svg="http://www.w3.org/2000/svg" -t -v "/svg:svg/@width" -o 'x' -v "/svg:svg/@height" "$path")
      convert -verbose -density 90 -background '#010105' <(hide_layers "$path" "$layername") -transparent-color '#010105' gif:- | convert gif:- -transparent '#010105' -background cyan -flatten -alpha off -compress none -type Palette -colors 256 -gravity center -crop "$size+0+0" BMP3:"$bmppath"
    elif grep -q "xlink:href.*png" "$path"; then
      [ "$pngpath" -nt "$path" ] && continue	# skip files that are newer
      pngpath=$(dirname "$path")/"$layername".png
      convert <(hide_layers "$path" "$layername") "$pngpath"
    fi
  done
done
