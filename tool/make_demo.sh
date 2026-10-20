#!/bin/sh
# Turns the scenes and sounds from tool/showcase_test.dart into the README's
# media: docs/media/demo.mp4 (with the voice), demo.gif (silent) and a
# 1600-pixel screenshot of each scene.
#
#   flutter test tool/showcase_test.dart && tool/make_demo.sh
#
# Needs ffmpeg.
set -eu
cd "$(dirname "$0")/.."
media=docs/media
sounds=build/showcase
fade=0.6

# Each scene's length in seconds, and the sound that starts 0.8 s into it.
set -- \
  "scene-1-clock 4" \
  "scene-2-speak 6.5 speak" \
  "scene-3-voices 7.5 classic" \
  "scene-4-dark 4" \
  "scene-5-quiet 4.5" \
  "scene-6-timer 5 timer" \
  "scene-7-end 4"

inputs="" video="" audio="" mix="" start=0 n=0 sound_n=$#
for scene in "$@"; do
  set -- $scene
  inputs="$inputs -loop 1 -framerate 30 -t $2 -i $sounds/$1.png"
  [ "$1" = scene-7-end ] ||
    ffmpeg -loglevel error -y -i "$sounds/$1.png" -vf scale=1600:-1 "$media/$1.png"
  if [ $n -eq 0 ]; then
    video="[0:v]scale=1920:1200,format=yuv420p[v0];"
    last=v0
  else
    offset=$(awk "BEGIN{print $start - $fade}")
    video="$video[$n:v]scale=1920:1200,format=yuv420p[s$n];[$last][s$n]xfade=transition=fade:duration=$fade:offset=$offset[v$n];"
    last=v$n
    start=$offset
  fi
  if [ $# -ge 3 ]; then
    delay=$(awk "BEGIN{print int(($start + 0.8) * 1000)}")
    audio="$audio $3:$delay"
  fi
  start=$(awk "BEGIN{print $start + $2}")
  n=$((n + 1))
done

a=0
for entry in $audio; do
  inputs="$inputs -i $sounds/${entry%%:*}.wav"
  mix="$mix[$((n + a)):a]aresample=48000,adelay=${entry##*:}:all=1[a$a];"
  a=$((a + 1))
done
labels=""
i=0
while [ $i -lt $a ]; do labels="$labels[a$i]"; i=$((i + 1)); done

# shellcheck disable=SC2086
ffmpeg -loglevel error -y $inputs -filter_complex \
  "$video$mix${labels}amix=inputs=$a:normalize=0,apad[a]" \
  -map "[$last]" -map "[a]" -shortest -c:v libx264 -preset slow -crf 22 \
  -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart $media/demo.mp4

ffmpeg -loglevel error -y -i $media/demo.mp4 -vf \
  "fps=12,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=192:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  $media/demo.gif

ls -l $media
