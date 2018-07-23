#!/bin/bash

find -L ../BYOM ! -name 'Multi Language' -name '*.bmp' -o -name '*.png' | while read path; do
  basepath=$(dirname "$path")
  relpath=$(echo "$path" | sed 's|^../BYOM/||')
  dir=$(dirname "$relpath")  # the dir inside the new theme
  parentdir="../"$(echo "$dir" | sed 's|[^/]\+|..|g')"/BYOM/$dir"
  file=$(basename "$path")
  name=$(basename "$file" .bmp)
  name=$(basename "$name" .png)
  # look for related images
  if echo "$name" | grep -q '_[a-z]$'; then
    name=$(echo "$name" | sed 's|_[a-z]$||')
    file=$(cd "$basepath"; ls "${name}"_?.{bmp,png} 2>/dev/null)
  fi

  info=$(file "$path")
  dimensions=$(echo "$info" | sed 's|.*, \([0-9]\+\) x \([0-9]\+\).*|\1x\2|')
  width=$(echo "$dimensions" | cut -dx -f1)
  height=$(echo "$dimensions" | cut -dx -f2)

  embeds=$(echo "$file" | while read file; do
  name=$(basename "$file" .bmp)
  name=$(basename "$name" .png)
  cat <<EOF
  <g
    inkscape:label="Original $name"
    inkscape:groupmode="layer"
    sodipodi:insensitive="true"
    id="Original_$name">
    <image
      xlink:href="$parentdir/$file"
      x="0"
      y="0"
      height="$height"
      width="$width"
    />
  </g>
EOF
  done
  )
  newlayers=$(echo "$file" | while read file; do
  name=$(basename "$file" .bmp)
  name=$(basename "$name" .png)
  cat <<EOF
  <g
    inkscape:label="New $name"
    inkscape:groupmode="layer"
    id="New_$name">
  </g>
EOF
  done
  )

  test -e "$dir" || mkdir -p "$dir"
  dest="$dir/$name.svg"
  test -e "$dest" || cat > "$dest" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns="http://www.w3.org/2000/svg"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   height="$height"
   width="$width"
   version="1.1"
>
$embeds
$newlayers
</svg>
EOF

done
