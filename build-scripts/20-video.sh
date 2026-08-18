#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

fetch_source x264
cd /src/x264 && ./configure --prefix="$PREFIX" --enable-static --enable-pic --disable-opencl --disable-cli && make $MAKEFLAGS && make install

fetch_source x265
cmake_static -S /src/x265/source -B /src/x265-build -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DHIGH_BIT_DEPTH=OFF -DEXPORT_C_API=ON
ninja -C /src/x265-build && ninja -C /src/x265-build install
# Upstream's generated file is authoritative; only supply one for releases that omit it.
install_pc_if_missing "$PREFIX/lib/pkgconfig/x265.pc" x265 "H.265/HEVC encoder (x265)" "$(lock x265 version)" -lx265 "-lstdc++ -lm -lpthread -ldl"

fetch_source libvpx
cd /src/libvpx && ./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-examples --disable-tools --disable-docs --disable-unit-tests --as=yasm && make $MAKEFLAGS && make install

fetch_source libaom
cmake_static -S /src/libaom -B /src/libaom-build -DENABLE_TESTS=OFF -DENABLE_TOOLS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_DOCS=OFF -DENABLE_TESTDATA=OFF
ninja -C /src/libaom-build && ninja -C /src/libaom-build install

fetch_source dav1d
meson setup /src/dav1d-build /src/dav1d --prefix="$PREFIX" --libdir=lib -Ddefault_library=static -Denable_tools=false -Denable_tests=false
ninja -C /src/dav1d-build && ninja -C /src/dav1d-build install

fetch_source svt_av1
cmake_static -S /src/svt_av1 -B /src/svt-build -DSVT_AV1_BUILD_APPS=OFF -DREPRODUCIBLE_BUILDS=ON
ninja -C /src/svt-build && ninja -C /src/svt-build install

fetch_source rav1e
cd /src/rav1e && cargo cinstall --locked --release --prefix="$PREFIX" --libdir="$PREFIX/lib" --includedir="$PREFIX/include" --pkgconfigdir="$PREFIX/lib/pkgconfig" --library-type=staticlib
test -f "$PREFIX/lib/pkgconfig/rav1e.pc" && cp -f "$PREFIX/lib/pkgconfig/rav1e.pc" "$PREFIX/lib/pkgconfig/librav1e.pc"
test -f "$PREFIX/include/rav1e.h" || ln -s rav1e/rav1e.h "$PREFIX/include/rav1e.h"

fetch_source openh264
cd /src/openh264 && make $MAKEFLAGS STATIC_LDFLAGS=-static && make PREFIX="$PREFIX" install-static
install_pc_if_missing "$PREFIX/lib/pkgconfig/openh264.pc" openh264 "OpenH264 codec library" "$(lock openh264 version)" -lopenh264 "-lstdc++ -lpthread -lm"

fetch_source openjpeg
cmake_static -S /src/openjpeg -B /src/openjpeg-build -DBUILD_CODEC=OFF -DBUILD_PKGCONFIG_FILES=ON
ninja -C /src/openjpeg-build && ninja -C /src/openjpeg-build install

fetch_source libwebp
cmake_static -S /src/libwebp -B /src/libwebp-build -DWEBP_BUILD_EXTRAS=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF
ninja -C /src/libwebp-build && ninja -C /src/libwebp-build install

fetch_source vvenc
cmake_static -S /src/vvenc -B /src/vvenc-build -DVVENC_ENABLE_APP=OFF
ninja -C /src/vvenc-build && ninja -C /src/vvenc-build install
install_pc_if_missing "$PREFIX/lib/pkgconfig/vvenc.pc" vvenc "Fraunhofer VVenC VVC encoder" "$(lock vvenc version)" -lvvenc "-lstdc++ -lpthread -lm"

printf '%s\n' '#include <x265.h>' 'int main(){x265_param p; x265_param_default(&p);}' >/tmp/x265-test.cpp
c++ -O2 -I"$PREFIX/include" /tmp/x265-test.cpp $(pkg-config --libs --static x265) -o /tmp/x265-test
/tmp/x265-test
