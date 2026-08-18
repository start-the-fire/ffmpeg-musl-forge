#!/usr/bin/env bash
set -euo pipefail
for binary in /out/ffmpeg /out/ffprobe /out/raw2bmx /out/bmxtranswrap; do
  ! readelf -l "$binary" | grep -q INTERP
  ! readelf -d "$binary" | grep -q NEEDED
done
/out/ffmpeg -version
/out/ffprobe -version
ffmpeg=/out/ffmpeg
has() { grep -Eq "$2" <<<"$1" || { echo "missing feature: $3" >&2; return 1; }; }
protocols=$($ffmpeg -hide_banner -protocols 2>&1)
has "$protocols" '(^|[[:space:]])https($|[[:space:]])' 'HTTPS protocol'
encoders=$($ffmpeg -hide_banner -encoders 2>&1)
for spec in 'libx264:H.264/x264' 'libx265:H.265/x265' 'libaom-av1:libaom AV1' 'libsvtav1:SVT-AV1' 'librav1e:rav1e AV1' 'libmp3lame:MP3' 'libopus:Opus' 'libvorbis:Vorbis' 'prores_ks:ProRes' 'dnxhd:DNxHD'; do
  has "$encoders" "(^|[[:space:]])${spec%%:*}([[:space:]]|$)" "${spec#*:} encoder"
done
decoders=$($ffmpeg -hide_banner -decoders 2>&1)
has "$decoders" '(^|[[:space:]])libdav1d([[:space:]]|$)' 'dav1d AV1 decoder'
filters=$($ffmpeg -hide_banner -filters 2>&1)
has "$filters" '(^|[[:space:]])ass([[:space:]]|$)' 'libass subtitle filter'
has "$filters" '(^|[[:space:]])subtitles([[:space:]]|$)' 'subtitle rendering filter'
/out/ffprobe -v error -show_program_version -of json >/tmp/ffprobe.json
grep -q program_version /tmp/ffprobe.json
/out/raw2bmx --help >/dev/null
/out/bmxtranswrap --help >/dev/null
