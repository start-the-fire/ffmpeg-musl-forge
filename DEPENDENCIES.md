# Dependency and license inventory

`versions.lock` is the authoritative record of the exact version, revision, source URL, and SHA-256 used by a build. This inventory records the corresponding upstream license families; upstream license files remain authoritative.

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

## Release checklist

For every published architecture:

1. Include the exact `versions.lock` and `SHA256SUMS` beside the binaries.
2. Capture `ffmpeg -version`, including its configuration line.
3. Retain or provide durable access to the corresponding source archives named by the lock file.
4. Include the complete license notices from FFmpeg and all linked dependencies.
5. Satisfy GPL corresponding-source requirements for the binaries and build scripts; do not treat this summary as legal advice.
