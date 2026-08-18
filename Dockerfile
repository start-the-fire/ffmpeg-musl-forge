# syntax=docker/dockerfile:1.25
# check=skip=InvalidDefaultArgInFrom
# Supplied by the Makefile from the version and digest in versions.lock.
# Deliberately has no fallback: builds must not silently bypass the lock.
ARG ALPINE_IMAGE
FROM ${ALPINE_IMAGE} AS build
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS=-j8
ARG BUILD_ID=dev
ENV PREFIX=${PREFIX} MAKEFLAGS=${MAKEFLAGS} BUILD_ID=${BUILD_ID} \
    RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:/opt/ffmpeg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN apk add --no-cache bash curl ca-certificates jq build-base pkgconf yasm nasm \
    cmake meson ninja autoconf automake libtool python3 py3-pip perl xz tar coreutils \
    diffutils binutils file openssl-dev openssl-libs-static zlib-dev zlib-static linux-headers
WORKDIR /build
COPY versions.lock /build/versions.lock
RUN set -eux; arch=$(apk --print-arch); \
    case "$arch" in x86_64) key=rustup_x86_64;; aarch64) key=rustup_aarch64;; *) exit 1;; esac; \
    url=$(jq -er --arg k "$key" '.tools[$k].url' versions.lock); \
    sha=$(jq -er --arg k "$key" '.tools[$k].sha256' versions.lock); \
    curl --fail --location --show-error --retry 3 -o /tmp/rustup-init "$url"; \
    echo "$sha  /tmp/rustup-init" | sha256sum -c -; chmod +x /tmp/rustup-init; \
    toolchain=$(jq -er '.tools.rust_toolchain.version' versions.lock); \
    /tmp/rustup-init -y --profile minimal --default-toolchain "$toolchain"; \
    cargo_c=$(jq -er '.tools.cargo_c.version' versions.lock); \
    cargo install cargo-c --version "$cargo_c" --locked; rustc --version; cargo cinstall --version
RUN set -eux; url=$(jq -er '.tools.meson.url' versions.lock); sha=$(jq -er '.tools.meson.sha256' versions.lock); \
    wheel="/tmp/$(basename "$url")"; curl --fail --location --show-error --retry 3 -o "$wheel" "$url"; \
    echo "$sha  $wheel" | sha256sum -c -; \
    pip install --break-system-packages --no-deps "$wheel"; meson --version
COPY --chmod=755 build-scripts/00-common.sh build-scripts/10-audio.sh /build/build-scripts/
RUN /build/build-scripts/10-audio.sh
COPY --chmod=755 build-scripts/20-video.sh /build/build-scripts/
RUN /build/build-scripts/20-video.sh
RUN apk add --no-cache gperf
COPY --chmod=755 build-scripts/30-subtitles.sh /build/build-scripts/
RUN /build/build-scripts/30-subtitles.sh
RUN apk add --no-cache util-linux-dev util-linux-static
COPY --chmod=755 build-scripts/35-formats.sh /build/build-scripts/
RUN /build/build-scripts/35-formats.sh
COPY --chmod=755 prepare-ffmpeg.sh /build/prepare-ffmpeg.sh
RUN /build/prepare-ffmpeg.sh
ARG BUILD_DATE=unknown
COPY --chmod=755 build-scripts/90-ffmpeg.sh /build/build-scripts/
RUN /build/build-scripts/90-ffmpeg.sh || { tail -200 /src/ffmpeg/ffbuild/config.log; exit 1; }
COPY --chmod=755 build-scripts/99-verify.sh /build/build-scripts/
RUN /build/build-scripts/99-verify.sh
FROM scratch AS export
COPY --from=build /out/ffmpeg /ffmpeg
COPY --from=build /out/ffprobe /ffprobe
COPY --from=build /out/raw2bmx /raw2bmx
COPY --from=build /out/bmxtranswrap /bmxtranswrap
ENTRYPOINT ["/ffmpeg"]
