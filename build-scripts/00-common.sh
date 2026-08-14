#!/usr/bin/env bash
set -euo pipefail

: "${PREFIX:=/opt/ffmpeg}"
: "${SRC_DIR:=/src}"
: "${MAKEFLAGS:=-j$(getconf _NPROCESSORS_ONLN)}"
: "${LOCK_FILE:=/build/versions.lock}"

export PATH="${PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:/usr/lib/pkgconfig"
export CFLAGS="${CFLAGS:--O2}"
export CXXFLAGS="${CXXFLAGS:--O2}"

lock() { jq -er --arg n "$1" --arg k "$2" '.sources[$n][$k]' "$LOCK_FILE"; }

fetch_source() {
  local name=$1 dest=${2:-$1} url sha archive strip
  url=$(lock "$name" url)
  sha=$(lock "$name" sha256)
  strip=$(jq -er --arg n "$name" '.sources[$n].strip_components // 1' "$LOCK_FILE")
  archive="/tmp/${name}.tar.gz"
  curl --fail --location --show-error --retry 3 --output "$archive" "$url"
  printf '%s  %s\n' "$sha" "$archive" | sha256sum -c -
  mkdir -p "$SRC_DIR/$dest"
  tar -xf "$archive" --strip-components="$strip" -C "$SRC_DIR/$dest"
  rm -f "$archive"
}

cmake_static() {
  cmake -G Ninja -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release "$@"
}

install_pc_if_missing() {
  local file=$1 name=$2 description=$3 version=$4 libs=$5 private=${6:-}
  test -f "$file" && return 0
  mkdir -p "$(dirname "$file")"
  printf '%s\n' \
    "prefix=${PREFIX}" 'exec_prefix=${prefix}' 'libdir=${prefix}/lib' \
    'includedir=${prefix}/include' '' "Name: ${name}" \
    "Description: ${description}" "Version: ${version}" \
    'Libs: -L${libdir} '"${libs}" "Libs.private: ${private}" \
    'Cflags: -I${includedir}' > "$file"
}

mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/include" "$PREFIX/bin" "$SRC_DIR"
