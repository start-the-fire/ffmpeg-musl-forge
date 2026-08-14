#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh
fetch_source ffmpeg
cd /src/ffmpeg
PKG_CONFIG='pkg-config --static' ./configure --prefix="$PREFIX" --pkg-config-flags=--static \
  --extra-cflags="-I${PREFIX}/include -O2" --extra-ldflags="-L${PREFIX}/lib -static" \
  --extra-libs='-lm -lpthread -lstdc++' \
  --extra-version="forge-${BUILD_ID:-dev}-${BUILD_DATE:-unknown}" \
  --disable-shared --enable-static --disable-debug --disable-doc --disable-ffplay \
  --enable-runtime-cpudetect --enable-gpl --enable-version3 --enable-openssl \
  --enable-libaom --enable-libdav1d --enable-libopenh264 --enable-libopenjpeg \
  --enable-librav1e --enable-libsvtav1 --enable-libtheora --enable-libvpx \
  --enable-libvvenc --enable-libwebp --enable-libx264 --enable-libx265 \
  --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libass \
  --enable-libfreetype --enable-libfontconfig --enable-libfribidi --enable-libharfbuzz \
  --enable-encoder=prores_ks --enable-encoder=prores_aw --enable-encoder=dnxhd --enable-pic
make $MAKEFLAGS
strip ffmpeg ffprobe
install -Dm755 ffmpeg /out/ffmpeg
install -Dm755 ffprobe /out/ffprobe
