#!/usr/bin/env bash
# Re-export every printable part to ../stl and preview images to ../images.
# Needs OpenSCAD; image rendering on a headless machine also needs xvfb-run.
set -euo pipefail
cd "$(dirname "$0")"
SCAD=longhaul_quad.scad
PARTS="hub_bottom hub_top motor_mount leg battery_tray camera_mount gps_mast"
mkdir -p ../stl ../images
RUN=""; command -v xvfb-run >/dev/null && [ -z "${DISPLAY:-}" ] && RUN="xvfb-run -a"
IMG="--colorscheme=Tomorrow --autocenter --viewall"
for p in $PARTS; do
  echo "exporting $p"
  openscad -q -D "part=\"$p\"" -o "../stl/$p.stl" "$SCAD"
  $RUN openscad -q $IMG --imgsize=800,600 --camera=0,0,0,55,0,25,0 -D "part=\"$p\"" -o "../images/$p.png" "$SCAD"
done
$RUN openscad -q $IMG --imgsize=1400,1000 --camera=0,0,0,60,0,35,0 -o ../images/assembly.png "$SCAD"
$RUN openscad -q $IMG --imgsize=1400,1000 --camera=0,0,0,90,0,0,0 --projection=o -o ../images/assembly_side.png "$SCAD"
$RUN openscad -q $IMG --imgsize=1400,1000 --camera=0,0,0,0,0,0,0 --projection=o -o ../images/assembly_top.png "$SCAD"
echo done
