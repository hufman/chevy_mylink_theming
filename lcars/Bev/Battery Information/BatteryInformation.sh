#!/bin/bash

[ -d output ] || mkdir output
frame=0

# main entry
for i in BEV_Powerflow_entry_*.bmp; do
  out=`printf 'output/%02i.bmp' "$frame"`; frame=$((frame+1))
  cp "$i" "$out"
done

# filling up battery gauge
for i in charge_0*.bmp charge_10.bmp; do
  out=`printf 'output/%02i.bmp' "$frame"`; frame=$((frame+1))
  convert -size 800x334 canvas:black \
    bg_left.bmp +composite \
    bg_top.bmp -geometry +346+0 +composite \
    bg_bottom.bmp -geometry +346+198 +composite \
    bg_right.bmp -geometry +706+0 +composite \
    ani_left_stop.bmp -geometry +76+0 +composite \
    ani_right_stop.bmp -geometry +706+0 +composite \
    "$i" -geometry +346+68 +composite \
    "$out"
  # slow this animation
  dupout=`printf 'output/%02i.bmp' "$frame"`; frame=$((frame+1))
  cp "$out" "$dupout"
done

# spinning the wheels
for i in `seq 0 14`; do
  out=`printf 'output/%02i.bmp' "$frame"`; frame=$((frame+1))
  convert -size 800x334 canvas:black \
    bg_left.bmp +composite \
    bg_top.bmp -geometry +346+0 +composite \
    bg_bottom.bmp -geometry +346+198 +composite \
    bg_right.bmp -geometry +706+0 +composite \
    `printf 'ani_left_%02i.bmp' "$i"` -geometry +76+0 +composite \
    `printf 'ani_right_%02i.bmp' "$i"` -geometry +536+0 +composite \
    charge_10.bmp -geometry +346+68 +composite \
    "$out"
done
# go backwards
for i in `seq 0 14`; do
  out=`printf 'output/%02i.bmp' "$frame"`; frame=$((frame+1))
  convert -size 800x334 canvas:black \
    bg_left.bmp +composite \
    bg_top.bmp -geometry +346+0 +composite \
    bg_bottom.bmp -geometry +346+198 +composite \
    bg_right.bmp -geometry +706+0 +composite \
    `printf 'ani_reverse_left_%02i.bmp' "$i"` -geometry +76+0 +composite \
    `printf 'ani_right_%02i.bmp' "$i"` -geometry +536+0 +composite \
    charge_10.bmp -geometry +346+68 +composite \
    "$out"
done
