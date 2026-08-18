#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

fetch_source uriparser
cmake_static -S /src/uriparser -B /src/uriparser-build -DURIPARSER_BUILD_TESTS=OFF
ninja -C /src/uriparser-build && ninja -C /src/uriparser-build install

fetch_source bmxlib
cmake_static -S /src/bmxlib -B /src/bmxlib-build -DBMX_BUILD_LIB_ONLY=ON
ninja -C /src/bmxlib-build && ninja -C /src/bmxlib-build install
