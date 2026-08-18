# Dependency and license inventory

`versions.lock` is the authoritative record of the exact version, revision, source URL, and SHA-256 used by a build. This inventory records upstream license families for review purposes only. It is not a complete third-party notice, does not replace the exact upstream license and attribution files, and is not legal advice.

| Component | License family |
| --- | --- |
| FFmpeg (configured with GPL and version 3 features) | GPL-3.0-or-later |
| x264 | GPL-2.0-or-later or commercial |
| x265 | GPL-2.0-or-later or commercial |
| ogg, vorbis, theora, opus | BSD-style |
| libvpx, libaom | BSD-style |
| dav1d, rav1e | BSD-2-Clause |
| SVT-AV1 | BSD-3-Clause |
| OpenH264 | BSD-2-Clause |
| OpenJPEG | BSD-2-Clause |
| WebP | BSD-3-Clause |
| VVenC | BSD-3-Clause |
| LAME | LGPL-2.0-or-later |
| Expat | MIT |
| FreeType | FreeType License or GPL-2.0-only |
| HarfBuzz | MIT-style |
| FriBidi | LGPL-2.1-or-later |
| Fontconfig | MIT-style |
| libass | ISC |
| OpenSSL | Apache-2.0 |
| musl | MIT |
| zlib | Zlib |
| GCC runtime libraries, including libstdc++ | GPL-3.0-or-later with GCC Runtime Library Exception |
| Rust crates incorporated through rav1e | Per-crate licenses recorded by rav1e's locked dependency graph; collect and review exact notices for each release |
| **bmxlib (BMX)** | **BSD-3-Clause** |
| **libMXF** (included with bmxlib) | **BSD-3-Clause** |
| **libMXF++** (included with bmxlib) | **BSD-3-Clause** |
| **uriparser** | **BSD-3-Clause** |

## Release checklist

For every published architecture:

1. Include the exact `versions.lock` and `SHA256SUMS` beside the binaries.
2. Capture `ffmpeg -version`, including its configuration line.
3. Retain or provide durable access to the corresponding source archives named by the lock file.
4. Include the complete license notices from FFmpeg and all linked dependencies.
5. Attach matching corresponding source for FFmpeg, all statically linked dependencies, vendored Rust crates, local modifications, and the build scripts; upstream URLs alone should not be treated as a durable source offer.
6. State clearly that the repository's MIT license applies to its original scripts and documentation, while the distributed binaries are GPL-3.0-or-later.
7. Review codec patent obligations separately from copyright-license compliance.
