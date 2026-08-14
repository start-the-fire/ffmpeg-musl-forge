#!/usr/bin/env bash
set -euo pipefail
source /build/build-scripts/00-common.sh

# x265's generated metadata inherits the compiler's shared runtime flags. In
# particular, -lgcc_s is unavailable in Alpine's fully static musl toolchain.
# Record x265's real static transitive dependencies instead.
rm -f "$PREFIX/lib/pkgconfig/x265.pc"
install_pc_if_missing "$PREFIX/lib/pkgconfig/x265.pc" x265 "H.265/HEVC encoder" \
  "$(lock x265 version)" -lx265 "-lstdc++ -lm -lpthread -ldl"

# cargo-c's pc filename/metadata has varied; provide both FFmpeg probe names.
rm -f "$PREFIX/lib/pkgconfig/rav1e.pc" "$PREFIX/lib/pkgconfig/librav1e.pc"
install_pc_if_missing "$PREFIX/lib/pkgconfig/rav1e.pc" rav1e "rav1e AV1 encoder" "$(lock rav1e version)" -lrav1e "-ldl -lpthread -lm"
cp "$PREFIX/lib/pkgconfig/rav1e.pc" "$PREFIX/lib/pkgconfig/librav1e.pc"
pkg-config --exists --print-errors --static 'rav1e >= 0.5.0'
