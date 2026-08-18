#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

fetch_source uriparser
cmake_static -S /src/uriparser -B /src/uriparser-build \
  -DURIPARSER_BUILD_DOCS=OFF \
  -DURIPARSER_BUILD_TESTS=OFF \
  -DURIPARSER_BUILD_TOOLS=OFF \
  -DURIPARSER_SHARED_LIBS=OFF
ninja -C /src/uriparser-build && ninja -C /src/uriparser-build install

fetch_source bmxlib
cmake_static -S /src/bmxlib -B /src/bmxlib-build \
  -DBMX_BUILD_LIB_ONLY=OFF \
  -DBMX_BUILD_WITH_LIBCURL=OFF \
  -DCMAKE_EXE_LINKER_FLAGS=-static
ninja -C /src/bmxlib-build && ninja -C /src/bmxlib-build install

mkdir -p /out
for tool in raw2bmx bmxtranswrap; do
  test -x "${PREFIX}/bin/${tool}"
  strip "${PREFIX}/bin/${tool}"
  install -Dm755 "${PREFIX}/bin/${tool}" "/out/${tool}"
done
