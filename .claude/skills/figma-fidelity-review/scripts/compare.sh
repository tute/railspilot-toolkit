#!/usr/bin/env bash
# compare.sh <figma.png> <app.png> <outprefix> [width]
# Writes <outprefix>-side.png (Figma | app), <outprefix>-diff.png (difference) and prints the
# pixel-error ratio of the common area. Both images are resized to <width> (default: app width).
set -euo pipefail
fig=$1; app=$2; out=$3
w=${4:-$(magick identify -format %w "$app")}
tmp=$(mktemp -d)
magick "$fig" -resize "${w}x" +repage "$tmp/fig.png"
magick "$app" -resize "${w}x" +repage "$tmp/app.png"
h=$(( $(magick identify -format %h "$tmp/fig.png") < $(magick identify -format %h "$tmp/app.png") ? $(magick identify -format %h "$tmp/fig.png") : $(magick identify -format %h "$tmp/app.png") ))
magick "$tmp/fig.png" -crop "${w}x${h}+0+0" +repage "$tmp/figc.png"
magick "$tmp/app.png" -crop "${w}x${h}+0+0" +repage "$tmp/appc.png"
magick "$tmp/fig.png" "$tmp/app.png" +append "$out-side.png"
magick "$tmp/figc.png" "$tmp/appc.png" -compose difference -composite -auto-level "$out-diff.png"
ae=$(magick compare -metric AE -fuzz 8% "$tmp/figc.png" "$tmp/appc.png" null: 2>&1 || true)
echo "common ${w}x${h} differing_pixels=${ae} ratio=$(awk -v a="$ae" -v n=$((w*h)) 'BEGIN{printf "%.4f", a/n}')"
