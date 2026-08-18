# Supported Codecs and File Formats

This document provides a comprehensive overview of the codecs and file formats supported by the ffmpeg-musl-forge extended build.

## Video Codecs

### AV1 Codec
- **Encoders**: `libsvtav1`, `librav1e`, `libaom`
- **Decoders**: `libdav1d`
- **Status**: ✅ Fully supported
- **Library Versions**: SVT-AV1 4.2.0, rav1e 0.8.1, libdav1d 1.5.4, libaom 3.14.1
- **Notes**: Multiple encoding options available; dav1d decoder is optimized for performance

### H.264/AVC
- **Encoders**: `libx264`
- **Decoders**: `h264` (native FFmpeg)
- **Status**: ✅ Fully supported
- **Library Version**: x264 stable branch
- **Notes**: Industry standard, widely compatible

### H.265/HEVC
- **Encoders**: `libx265`
- **Decoders**: `hevc` (native FFmpeg)
- **Status**: ✅ Fully supported
- **Library Version**: x265 4.2
- **Notes**: Modern video compression, superior quality/bitrate ratio

### VP8/VP9
- **Encoders**: `libvpx`
- **Decoders**: `libvpx` (VP8), `libvpx-vp9` (VP9)
- **Status**: ✅ Fully supported
- **Library Version**: libvpx 1.16.0
- **Notes**: Open source codec; VP9 supports 4K and high frame rates

### Theora
- **Encoders**: `libtheora`
- **Decoders**: `libtheora`
- **Status**: ✅ Fully supported
- **Library Version**: libtheora 1.2.0
- **Notes**: Patent-free, supported in Firefox and other open-source projects

### MPEG-2
- **Encoders**: `prores_ks`, `dnxhd` (wrapper support)
- **Decoders**: `mpeg2video` (native FFmpeg)
- **Status**: ✅ Fully supported
- **Notes**: Legacy format; included for compatibility

### JPEG 2000
- **Encoders**: `libopenjpeg`
- **Decoders**: `libopenjpeg`
- **Status**: ✅ Fully supported
- **Library Version**: OpenJPEG 2.5.4
- **Notes**: High-quality lossy/lossless compression; used in cinema and archival

### WebP
- **Encoders**: `libwebp`
- **Decoders**: `libwebp`
- **Status**: ✅ Fully supported
- **Library Version**: libwebp 1.6.0
- **Notes**: Modern image format; excellent for web; supports transparency and animation

### H.266/VVC
- **Encoders**: `libvvenc`
- **Decoders**: Not included (decoder available separately)
- **Status**: ✅ Encoder supported
- **Library Version**: VVenC 1.14.0
- **Notes**: Next-generation codec; 50% better compression than HEVC

### Uncompressed Video
- **Format**: UYVY, v210
- **Status**: ✅ Fully supported
- **Notes**: Professional production workflows

## Audio Codecs

### MP3
- **Encoders**: `libmp3lame`
- **Decoders**: `mp3` (native FFmpeg), `libmp3lame`
- **Status**: ✅ Fully supported
- **Library Version**: LAME 4.0
- **Notes**: Ubiquitous format; universal compatibility

### Opus
- **Encoders**: `libopus`
- **Decoders**: `libopus`
- **Status**: ✅ Fully supported
- **Library Version**: Opus 1.6.1
- **Notes**: Modern codec; excellent quality at low bitrates; supports adaptive streaming

### Vorbis
- **Encoders**: `libvorbis`
- **Decoders**: `libvorbis`
- **Status**: ✅ Fully supported
- **Library Version**: libvorbis 1.3.7
- **Notes**: Patent-free; mature codec; good quality

### Ogg Container
- **Format**: Ogg (for Vorbis/Opus)
- **Status**: ✅ Fully supported
- **Library Version**: libogg 1.3.6
- **Notes**: Open container format

### WAV (PCM Audio)
- **Format**: RIFF WAVE with PCM audio
- **Status**: ✅ Fully supported
- **Notes**: Uncompressed audio; used in professional audio workflows

## File Format Support

### MXF (Material Exchange Format)
- **Standards**: SMPTE ST 377-1
- **Wrapper Profiles**:
  - SMPTE ST 378 (OP1a)
  - SMPTE RDD 9 (MPEG Long GOP / Sony XDCAM)
  - SMPTE ST 386 (D-10 / Sony MPEG IMX)
  - AMWA AS-02 (MXF Versioning)
  - AMWA AS-10 (Production)
  - AMWA AS-11 (Media Contribution)
  - Avid native MXF OPAtom
- **Video Essence**: H.264, MPEG-2, AVC-Intra, DV, JPEG 2000, ProRes, VC-2, VC-3, uncompressed
- **Audio Essence**: PCM, MP3, Opus, Vorbis
- **Status**: ✅ Fully supported via `bmxlib` 1.7
- **Library**: BMX (BBC/EBU maintained)
- **Exported Applications**: `raw2bmx`, `bmxtranswrap`
- **Notes**: Professional broadcast standard; essential for post-production, file-based workflows

### IMF (Interoperable Master Format)
- **Standard**: SMPTE ST 2067-5
- **Status**: ✅ Fully supported
- **Notes**: Cinema and streaming distribution; based on MXF

### QuickTime/MP4
- **Containers**: MOV, MP4, M4A
- **Status**: ✅ Fully supported
- **Notes**: Industry standard; supported by most platforms

### WebM
- **Codec Support**: VP8/VP9 (video), Opus/Vorbis (audio)
- **Status**: ✅ Fully supported
- **Notes**: Open web media format; optimized for browser playback

## Text/Subtitles

### ASS/SSA (Advanced SubStation Alpha)
- **Status**: ✅ Fully supported
- **Library**: libass 0.17.5
- **Notes**: Complex subtitle format; supports styling, animations, karaoke

### IMSC 1 Timed Text
- **Status**: ✅ Fully supported
- **Notes**: W3C standard; used in professional broadcast and streaming

### SMPTE ST 436 ANC/VBI
- **Format**: Ancillary and Vertical Blanking Interval data encapsulation
- **Status**: ✅ Fully supported
- **Notes**: Professional video metadata and closed captioning

## Text Rendering Support

### Font Rendering Stack
- **FreeType**: 2.14.3 (font rasterization)
- **HarfBuzz**: 14.3.1 (text shaping)
- **Fontconfig**: 2.18.3 (font configuration)
- **FriBidi**: 1.0.16 (bidirectional text)
- **Status**: ✅ Fully supported
- **Notes**: Enables complex text rendering with international language support

## Build Characteristics

### Compilation Details
- **Base Image**: Alpine Linux 3.24.1 (musl libc)
- **Link Type**: Fully static (no shared library dependencies)
- **Platform Support**: Linux (x86_64, ARM64)
- **Build System**: CMake with Ninja
- **CPU-Only**: No hardware acceleration (by design)

### Capabilities
- ✅ Multiple video codec encoding options
- ✅ Professional broadcast format support (MXF)
- ✅ Modern streaming codecs (AV1, VP9, Opus)
- ✅ Advanced text rendering and subtitle support
- ✅ Patent-free alternatives available
- ✅ Commercial codec support (H.264, HEVC)

### Limitations (By Design)
- ❌ No hardware acceleration (CUDA, VAAPI, QSV, AMD AMF, Vulkan, VideoToolbox)
- ❌ No shared library linking (for maximum portability)
- ❌ CPU-only processing (ensures portability to all platforms)

## Recommended Use Cases

### ✅ Ideal For:
- Docker container deployments (including `scratch` images)
- Broadcast and professional media workflows
- MXF file creation and manipulation
- Portable CI/CD pipelines
- Batch transcoding on CPU-only infrastructure
- Kubernetes/cloud deployments
- Cross-platform media processing
- Post-production workflows requiring MXF support

### ⚠️ Not Ideal For:
- Real-time GPU-accelerated encoding/decoding
- Platform-specific hardware integration
- Systems requiring minimal binary size (binary is ~50MB due to static linking)
- Development environments (prefer dynamic builds)

## Version Summary

| Component | Version |
|-----------|---------|
| FFmpeg | 9.0.1 |
| x264 | Stable branch (b35605ace3dd) |
| x265 | 4.2 |
| libvpx | 1.16.0 |
| libaom | 3.14.1 |
| dav1d | 1.5.4 |
| SVT-AV1 | 4.2.0 |
| rav1e | 0.8.1 |
| OpenJPEG | 2.5.4 |
| libwebp | 1.6.0 |
| VVenC | 1.14.0 |
| LAME | 4.0 |
| Opus | 1.6.1 |
| libvorbis | 1.3.7 |
| libass | 0.17.5 |
| FreeType | 2.14.3 |
| HarfBuzz | 14.3.1 |
| Fontconfig | 2.18.3 |
| FriBidi | 1.0.16 |
| OpenH264 | 2.6.0 |
| libtheora | 1.2.0 |
| libogg | 1.3.6 |
| **bmxlib** | **1.7** |
| **libMXF** | Bundled with bmxlib |
| **uriparser** | **1.0.2** |

---

**Last Updated**: 2026-08-18
**Build Model**: ffmpeg-musl-forge extended profile
