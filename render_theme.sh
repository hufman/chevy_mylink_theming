#!/bin/bash

find . -name '*.svg' | while read path; do
  grep -q "StillImage" "$path" || continue
  if grep -q "xlink:href.*bmp" "$path"; then
    bmppath=$(dirname "$path")/$(basename "$path" .svg)".bmp"
    convert "$path" -type Palette -colors 256 BMP3:"$bmppath"
  elif grep -q "xlink:href.*png" "$path"; then
    pngpath=$(dirname "$path")/$(basename "$path" .svg)".png"
    convert "$path" "$pngpath"
  fi
done
