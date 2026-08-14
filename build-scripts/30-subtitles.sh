#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

fetch_source expat
cmake_static -S /src/expat/expat -B /src/expat-build -DEXPAT_SHARED_LIBS=OFF -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF
ninja -C /src/expat-build && ninja -C /src/expat-build install

fetch_source freetype
cmake_static -S /src/freetype -B /src/freetype-build -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=OFF -DFT_REQUIRE_BZIP2=OFF -DFT_REQUIRE_BROTLI=OFF
ninja -C /src/freetype-build && ninja -C /src/freetype-build install

fetch_source harfbuzz
meson setup /src/harfbuzz-build /src/harfbuzz --prefix="$PREFIX" --libdir=lib -Ddefault_library=static -Dglib=disabled -Dgobject=disabled -Dicu=disabled -Dtests=disabled -Dintrospection=disabled
ninja -C /src/harfbuzz-build && ninja -C /src/harfbuzz-build install

fetch_source fribidi
meson setup /src/fribidi-build /src/fribidi --prefix="$PREFIX" --libdir=lib -Ddefault_library=static -Ddocs=false -Dtests=false -Dbin=false
ninja -C /src/fribidi-build && ninja -C /src/fribidi-build install

fetch_source fontconfig
meson setup /src/fontconfig-build /src/fontconfig --prefix="$PREFIX" --libdir=lib -Ddefault_library=static -Ddoc=disabled -Dtests=disabled
ninja -C /src/fontconfig-build && ninja -C /src/fontconfig-build install

fetch_source libass
meson setup /src/libass-build /src/libass --prefix="$PREFIX" --libdir=lib -Ddefault_library=static -Dtest=disabled
ninja -C /src/libass-build && ninja -C /src/libass-build install
