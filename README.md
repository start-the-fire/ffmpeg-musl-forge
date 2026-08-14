# ffmpeg-musl-forge

Version-locked, fully static musl-linked Linux builds of `ffmpeg` and `ffprobe` for copying into Docker images—including `scratch` images. The extended profile includes H.264/H.265, AV1, VVC, WebP/JPEG 2000, MP3/Opus/Vorbis, and the libass/Fontconfig text stack.

## Status

The extended build has previously been verified on both `linux/arm64` and `linux/amd64`. The current lock must be rebuilt on both architectures after every update before publishing artifacts. Each build checks for the absence of an ELF interpreter and `NEEDED` shared-library entries before it reaches the scratch export stage.

This repository builds portable CPU-only binaries. Hardware acceleration belongs in a separate platform-specific, non-static/glibc build.

## Build and export

Docker with Buildx, GNU Make, Python 3, `jq`, and `rg` are required. On Apple Silicon, use the native ARM64 target:

```sh
make verify PLATFORM=linux/arm64 BUILD_ID=local
make export PLATFORM=linux/arm64 BUILD_ID=local
```

`make verify` builds the image before running its smoke tests, so a separate `make build` is optional. Use `PLATFORM=linux/amd64` for an emulated x86-64 build on an ARM Mac; it works but is substantially slower.

Exported filenames include the locked FFmpeg version, UTC build date, and architecture, for example `dist/ffmpeg-<version>-<YYYYMMDD>-arm64`. The build ID and date are also embedded in the suffix reported by `ffmpeg -version` and `ffprobe -version`, such as `<version>-forge-local-<YYYYMMDD>`.

By default `BUILD_DATE` is the current UTC date. Supply it explicitly for repeatable release metadata:

```sh
make export PLATFORM=linux/arm64 BUILD_ID=v1 BUILD_DATE=20260814
```

The exported executables can be copied directly into a scratch image:

```dockerfile
FROM scratch
COPY ffmpeg-<version>-<YYYYMMDD>-arm64 /ffmpeg
COPY ffprobe-<version>-<YYYYMMDD>-arm64 /ffprobe
ENTRYPOINT ["/ffmpeg"]
```

## Reproducible update model

Normal builds do not discover newer upstream releases. `versions.lock` pins Alpine (including its multi-architecture image digest), the Rust toolchain, cargo-c, source tags/revisions, source archive URLs and their SHA-256 values, and x264's explicit upstream `stable` revision. Source archives listed in the lock are checksum-verified before extraction.

The lock makes dependency updates explicit and reviewable, but it does not promise bit-for-bit reproducible output. Alpine packages are installed from the pinned image's configured repositories, rustup downloads the selected toolchain components, and `cargo install --locked` resolves cargo-c using its published Cargo lock. Published artifacts should therefore retain the lock file, binary checksums, build configuration, and CI provenance.

The Dockerfile intentionally has no default Alpine image. The Makefile reads the version and multi-architecture digest from `versions.lock` and supplies `ALPINE_IMAGE` to Buildx, so `make build`, `make verify`, `make export`, and CI all consume the same locked base image. A raw `docker build` must provide that argument explicitly; using the Make targets is recommended.

To propose updates:

```sh
make update-lock-all
git diff -- versions.lock
make build PLATFORM=linux/arm64 BUILD_ID=update-test
make build PLATFORM=linux/amd64 BUILD_ID=update-test-amd64
```

`update-foundations.sh` resolves Alpine's latest stable point release and multi-architecture image digest, the stable Rust toolchain, cargo-c's latest stable crate, LAME's best stable source release, and the current rustup installer checksums. Preview only those changes with `./update-foundations.sh --dry-run`, or apply them with `make update-foundations`.

`update-lock.py` updates the remaining source dependencies and Meson. `make update-lock-all` runs both updaters. The updater selects stable semantic-version tags. x264 is the documented exception because it has no numbered release stream; it records the exact commit at the upstream-maintained `stable` branch. Review and commit the lock diff before publishing artifacts; neither normal builds nor CI update it implicitly.

Useful update commands:

| Command | Effect |
| --- | --- |
| `./update-foundations.sh --dry-run` | Preview Alpine, Rust, cargo-c, rustup, and LAME changes |
| `make update-foundations` | Apply only those foundational updates |
| `make update-lock` | Update FFmpeg and the remaining source dependencies |
| `make update-lock-all` | Run both update stages |
| `make validate-lock` | Validate lock syntax and reject unsafe/unlocked patterns |

## Verification

The build fails if either ELF contains an interpreter or a `NEEDED` dynamic-library entry. It executes both programs and checks that the HTTPS protocol, required audio/video encoders, AV1 decoding, libass filters, ProRes, DNxHD, and ffprobe are present and usable for basic introspection. This is a feature-presence smoke test; it does not currently perform a live HTTPS download or encode sample media. CI builds native amd64 and arm64 artifacts monthly and on demand, and includes `SHA256SUMS` plus the exact lock file.

## Runtime data

Static linking does not embed CA certificates, fonts, or Fontconfig configuration. Consumers using HTTPS or subtitle rendering must copy an appropriate CA bundle, fonts, and Fontconfig data into the runtime image.

## Licensing and source obligations

The repository's original build scripts and documentation are available under the [MIT License](LICENSE). This does not relicense FFmpeg or any linked dependency.

The x264/x265-enabled binaries, built with FFmpeg's `--enable-version3`, are distributed under GPL-3.0-or-later. See [DEPENDENCIES.md](DEPENDENCIES.md) for the dependency and license inventory. Distributors must comply with FFmpeg and every linked dependency license, including corresponding-source obligations. Preserve `versions.lock`, the build configuration printed by `ffmpeg -version`, artifact checksums, license notices, and retrievable source archives alongside each release.

A smaller `core` profile may be added later; this repository currently preserves the extended profile.
