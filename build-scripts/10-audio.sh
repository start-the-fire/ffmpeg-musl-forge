#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

fetch_source ogg
cd /src/ogg && test -x ./configure || ./autogen.sh
cd /src/ogg && ./configure --prefix="$PREFIX" --enable-static --disable-shared && make $MAKEFLAGS && make install

fetch_source vorbis
cd /src/vorbis && test -x ./configure || ./autogen.sh
cd /src/vorbis && ./configure --prefix="$PREFIX" --enable-static --disable-shared && make $MAKEFLAGS && make install

fetch_source theora
cd /src/theora && test -x ./configure || ./autogen.sh
cd /src/theora && ./configure --prefix="$PREFIX" --enable-static --disable-shared --disable-examples --disable-oggtest --disable-vorbistest && make $MAKEFLAGS && make install

fetch_source opus
cd /src/opus && test -x ./configure || ./autogen.sh
cd /src/opus && ./configure --prefix="$PREFIX" --enable-static --disable-shared && make $MAKEFLAGS && make install

fetch_source lame
cd /src/lame && ./configure --prefix="$PREFIX" --enable-static --disable-shared \
  --disable-frontend --disable-decoder && make $MAKEFLAGS && make install
# LAME 4.0's release archive can omit its public header from `make install`
# with the frontend disabled. FFmpeg includes it as <lame/lame.h>, so restore
# that documented layout from the checksum-verified source when necessary.
test -f "$PREFIX/include/lame/lame.h" || install -Dm644 /src/lame/include/lame.h "$PREFIX/include/lame/lame.h"
test -s "$PREFIX/include/lame/lame.h"
test -s "$PREFIX/lib/libmp3lame.a"
install_pc_if_missing "$PREFIX/lib/pkgconfig/libmp3lame.pc" libmp3lame "LAME MP3 encoder" "$(lock lame version)" -lmp3lame -lm
