#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

# Build libjxl's required static dependencies first. The libjxl release archive
# contains the integration points but not the Highway/Brotli submodule sources.
fetch_source highway
cmake_static -S /src/highway -B /src/highway-build \
  -DHWY_ENABLE_EXAMPLES=OFF -DHWY_ENABLE_TESTS=OFF -DHWY_ENABLE_CONTRIB=OFF
ninja -C /src/highway-build && ninja -C /src/highway-build install

fetch_source brotli
cmake_static -S /src/brotli -B /src/brotli-build \
  -DBROTLI_BUILD_TOOLS=OFF -DBROTLI_DISABLE_TESTS=ON
ninja -C /src/brotli-build && ninja -C /src/brotli-build install

# libjxl requires LCMS2 when its compact skcms path is disabled.
fetch_source lcms2
cmake_static -S /src/lcms2 -B /src/lcms2-build \
  -DLCMS2_BUILD_SHARED=OFF -DLCMS2_BUILD_STATIC=ON \
  -DLCMS2_BUILD_TOOLS=OFF -DLCMS2_BUILD_TESTS=OFF
ninja -C /src/lcms2-build && ninja -C /src/lcms2-build install

# Omit tools, tests, viewers, and optional integrations from libjxl.
fetch_source libjxl
cmake_static -S /src/libjxl -B /src/libjxl-build \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DJPEGXL_STATIC=ON \
  -DJPEGXL_FORCE_SYSTEM_HWY=ON \
  -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
  -DJPEGXL_FORCE_SYSTEM_LCMS2=ON \
  -DJPEGXL_ENABLE_TOOLS=OFF \
  -DJPEGXL_ENABLE_DEVTOOLS=OFF \
  -DJPEGXL_ENABLE_DOXYGEN=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_ENABLE_OPENEXR=OFF \
  -DJPEGXL_ENABLE_SKCMS=OFF \
  -DJPEGXL_ENABLE_TCMALLOC=OFF \
  -DJPEGXL_ENABLE_PLUGINS=OFF \
  -DJPEGXL_ENABLE_TRANSCODE_JPEG=OFF \
  -DJPEGXL_ENABLE_SJPEG=OFF \
  -DBUILD_TESTING=OFF
ninja -C /src/libjxl-build && ninja -C /src/libjxl-build install

fetch_source zimg
cd /src/zimg
./autogen.sh
./configure --prefix="$PREFIX" --enable-static --disable-shared
make $MAKEFLAGS && make install

fetch_source vmaf
meson setup /src/vmaf-build /src/vmaf/libvmaf --prefix="$PREFIX" --libdir=lib \
  -Dbuildtype=release -Ddefault_library=static \
  -Denable_tests=false -Denable_docs=false -Denable_tools=false \
  -Denable_cuda=false -Denable_nvtx=false -Denable_float=false \
  -Dbuilt_in_models=true
ninja -C /src/vmaf-build && ninja -C /src/vmaf-build install
