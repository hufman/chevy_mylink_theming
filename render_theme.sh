#!/bin/bash

required_colors="white yellow magenta red cyan lime blue black"

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
  echo "$layers" | while read layer; do
    layername=$(echo "$layer" | sed 's|New_||')

    if grep -q "xlink:href.*bmp" "$path"; then
      # prepare the palette to use
      convert -size 1x1 $(for color in $required_colors; do echo -n "xc:$color "; done) +append <(hide_layers "$path" "$layername") -unique-colors +append gif:/tmp/palette
      convert -size 1x1 $(for color in $required_colors; do echo -n "xc:$color "; done) +append <(hide_layers "$path" "$layername") -unique-colors +append txt:/tmp/palette_$layername

      bmppath=$(dirname "$path")/"$layername".bmp
      convert <(hide_layers "$path" "$layername") gif:- | convert - -dither None -remap /tmp/palette -alpha off -compress none -type Palette BMP3:"$bmppath"
    elif grep -q "xlink:href.*png" "$path"; then
      pngpath=$(dirname "$path")/"$layername".png
      convert <(hide_layers "$path" "$layername") "$pngpath"
    fi
  done
done
