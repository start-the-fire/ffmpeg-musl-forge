# ffmpeg-musl-forge

Version-locked, fully static, CPU-only musl-linked Linux builds of `ffmpeg` and `ffprobe` for copying into Docker images—including `scratch` images. The extended profile includes software support for H.264/H.265, AV1, H.266/VVC, WebP/JPEG 2000, MP3/Opus/Vorbis, the libass/Fontconfig text stack, and professional MXF file format support via `bmxlib`.

## Status

The extended build has previously been verified on both `linux/arm64` and `linux/amd64`. The current lock must be rebuilt on both architectures after every update before publishing artifacts. Each build checks for the absence of an ELF interpreter and `NEEDED` shared-library entries before it reaches the scratch export stage.

This repository builds portable CPU-only binaries. Hardware APIs and filters such as CUDA/NVENC, Vulkan, AMD AMF, VAAPI, Intel QSV, and Apple VideoToolbox are intentionally excluded because they require platform-specific drivers, frameworks, or runtime libraries. Hardware acceleration belongs in a separate platform-specific, non-static/glibc build and must not be mixed with this portable musl artifact.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/O5W625643K)

## Build and export

Docker with Buildx, GNU Make, Python 3, `jq`, and `rg` are required.

### Apple Silicon (ARM64) - Native Build

On Apple Silicon, use the native ARM64 target for optimal performance:

```sh
make verify PLATFORM=linux/arm64 BUILD_ID=local
make export PLATFORM=linux/arm64 BUILD_ID=local
```

### Apple Silicon (x86-64) - Emulated Build

For x86-64 binaries on Apple Silicon (emulated via Rosetta; substantially slower):

```sh
make build PLATFORM=linux/amd64 BUILD_ID=local-amd64
make export PLATFORM=linux/amd64 BUILD_ID=local-amd64
```

### Reproducible Release Builds

By default `BUILD_DATE` is the current UTC date. Supply it explicitly for repeatable release metadata:

```sh
make export PLATFORM=linux/arm64 BUILD_ID=v1 BUILD_DATE=20260814
make export PLATFORM=linux/amd64 BUILD_ID=v1-amd64 BUILD_DATE=20260814
```

### Build Notes

`make verify` builds the image before running its smoke tests, so a separate `make build` is optional for ARM64. The exported binaries include the locked FFmpeg version, UTC build date, and architecture in the filename, for example `dist/ffmpeg-<version>-<YYYYMMDD>-arm64` or `dist/ffmpeg-<version>-<YYYYMMDD>-amd64`. The build ID and date are also embedded in the suffix reported by `ffmpeg -version` and `ffprobe -version`, such as `<version>-forge-local-<YYYYMMDD>`.

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

## Supported Codecs and Formats

For a comprehensive list of all supported video codecs, audio codecs, and file formats including MXF, IMF, QuickTime, WebM, and broadcast formats, see [CODECS_FORMATS.md](CODECS_FORMATS.md).

### MXF (Material Exchange Format) Support

The build includes professional broadcast support for MXF file creation and manipulation via **bmxlib** 1.7:

- **MXF Standards**: SMPTE ST 377-1, SMPTE ST 378 (OP1a), SMPTE RDD 9 (XDCAM), SMPTE ST 386 (D-10)
- **Wrapper Profiles**: AMWA AS-02, AS-10, AS-11, and Avid OPAtom
- **Applications Included**:
  - `raw2bmx`: Create MXF files from raw essence
  - `bmxtranswrap`: Re-wrap MXF files
  - `mxf2raw`: Extract metadata and essence
  - `bmxparse`: Parse essence files
- **Use Cases**: Post-production workflows, broadcast file-based production, archival, standards compliance

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

The [MIT License](LICENSE) applies only to this repository's original build scripts and documentation. It does not apply to, or relicense, the exported `ffmpeg` and `ffprobe` binaries, FFmpeg, or any linked dependency.

The exported binaries include GPL components such as x264 and x265 and are built with FFmpeg's `--enable-gpl --enable-version3` options. The combined binaries must therefore be distributed under **GPL-3.0-or-later**, subject also to the notices and compatible terms of their other components. OpenSSL 3 is Apache-2.0 licensed; Apache-2.0 is compatible with GPLv3, and FFmpeg 9 permits this combination when `--enable-version3` is used. The build does not use `--enable-nonfree`.

[DEPENDENCIES.md](DEPENDENCIES.md) is an inventory, not a substitute for the complete upstream license and attribution texts. Anyone distributing the binaries is responsible for complying with FFmpeg and every statically linked dependency. Consult the [FFmpeg license documentation](https://github.com/FFmpeg/FFmpeg/blob/n9.0.1/LICENSE.md), the [GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.html), and the exact license files contained in the source archives recorded by `versions.lock`.

### Binary release checklist

Every binary release should provide, for each architecture:

1. The `ffmpeg` and `ffprobe` binaries and `SHA256SUMS`.
2. The exact committed `versions.lock` and tagged build scripts used to produce them.
3. `BUILDINFO.txt` containing the complete `ffmpeg -version` and `ffprobe -version` output, including the configure line.
4. The complete GPLv3 text and the exact copyright, license, attribution, and notice files for all included components. A license-family summary alone is insufficient.
5. Corresponding source that matches the binaries, including FFmpeg, all statically linked dependencies, applicable vendored Rust crates, local modifications, and the scripts needed to rebuild them. The safest approach is to attach this source bundle to the same GitHub release as the binaries; `versions.lock` and upstream links alone are not a durable replacement for corresponding source.
6. A clear statement on the GitHub release page that the repository code is MIT-licensed while the distributed binaries are GPL-3.0-or-later.

GitHub's automatically generated source archive contains this repository, but it does not contain the locked third-party dependency sources. Do not publish a binary release until the corresponding-source and license-notice assets are available. This project documentation is practical guidance, not legal advice.

### Codec patents

Some supported formats—including H.264/AVC, H.265/HEVC, AAC, and H.266/VVC—may be covered by patents. Copyright permission under an open-source license does not necessarily provide every patent authorization required for every jurisdiction, distribution model, or use case. In particular, do not assume that Cisco's patent arrangement for qualifying OpenH264 binaries distributed by Cisco automatically covers a separately built static OpenH264 binary. This project grants no patent rights beyond those expressly provided by the applicable upstream licenses. Distributors should obtain qualified legal advice for their intended markets and uses.
