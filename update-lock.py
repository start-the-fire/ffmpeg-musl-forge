#!/usr/bin/env python3
"""Resolve reviewed stable release channels and write checksum-pinned versions.lock."""
import hashlib, json, os, re, subprocess, sys, urllib.parse, urllib.request
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.abspath(__file__))
LOCK = os.path.join(ROOT, "versions.lock")
GH = {
    "ogg": "xiph/ogg", "vorbis": "xiph/vorbis", "theora": "xiph/theora",
    "opus": "xiph/opus",
    "libvpx": "webmproject/libvpx",
    "dav1d": "videolan/dav1d", "svt_av1": "AOMediaCodec/SVT-AV1",
    "rav1e": "xiph/rav1e", "openh264": "cisco/openh264",
    "openjpeg": "uclouvain/openjpeg", "libwebp": "webmproject/libwebp",
    "vvenc": "fraunhoferhhi/vvenc", "expat": "libexpat/libexpat",
    "freetype": "freetype/freetype", "harfbuzz": "harfbuzz/harfbuzz",
    "fribidi": "fribidi/fribidi", "fontconfig": "fontconfig/fontconfig",
    "libass": "libass/libass", "ffmpeg": "FFmpeg/FFmpeg",
}

def request(url, binary=False):
    headers = {"User-Agent": "ffmpeg-musl-forge-lock-updater", "Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if token: headers["Authorization"] = "Bearer " + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=120) as r:
        data = r.read()
    return data if binary else json.loads(data)

def latest_release(repo, name=None):
    output = subprocess.check_output(["git", "ls-remote", "--tags", f"https://github.com/{repo}.git"], text=True)
    tags = sorted({line.split("refs/tags/", 1)[1].removesuffix("^{}") for line in output.splitlines() if "refs/tags/" in line})
    stable = []
    for name in tags:
        if repo == "fontconfig/fontconfig" and not re.match(r"^[0-9]", name): continue
        if re.search(r"(?i)(alpha|beta|rc|dev|test|rfc|^xf-)", name): continue
        match = re.search(r"([0-9]+(?:[._-][0-9]+){1,3})", name)
        if match: stable.append((tuple(map(int, re.split(r"[._-]", match.group(1)))), name))
    if not stable: raise RuntimeError(f"no stable version tag found for {repo}")
    return max(stable)[1]

def digest(url):
    h = hashlib.sha256()
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"ffmpeg-musl-forge-lock-updater"}), timeout=300) as r:
        while chunk := r.read(1024 * 1024): h.update(chunk)
    return h.hexdigest()

def version(tag):
    value = re.sub(r"^(release[-_/]|VER-|R_|v|n)", "", tag, flags=re.I)
    return value.replace("_", ".").replace("-", ".")

def main():
    old = json.load(open(LOCK)) if os.path.exists(LOCK) else {}
    sources = {}
    for name, repo in GH.items():
        tag = latest_release(repo)
        url = f"https://github.com/{repo}/archive/refs/tags/{urllib.parse.quote(tag, safe='')}.tar.gz"
        print(f"{name}: {tag}", file=sys.stderr)
        sources[name] = {"version": version(tag), "revision": tag, "url": url, "sha256": digest(url), "update": "stable-release"}

    for name, filename in {"ogg":"libogg", "vorbis":"libvorbis", "theora":"libtheora", "opus":"opus"}.items():
        ver = sources[name]["version"]
        url = f"https://downloads.xiph.org/releases/{name}/{filename}-{ver}.tar.gz"
        sources[name].update(url=url, sha256=digest(url), archive="upstream-release-tarball")

    tags = request("https://api.bitbucket.org/2.0/repositories/multicoreware/x265_git/refs/tags?sort=-target.date&pagelen=100")
    tag = next(x["name"] for x in tags["values"] if re.fullmatch(r"[0-9]+(?:\.[0-9]+)+", x["name"]))
    url = f"https://bitbucket.org/multicoreware/x265_git/get/{tag}.tar.gz"
    sources["x265"] = {"version": tag, "revision": tag, "url": url, "sha256": digest(url), "update": "stable-release"}

    refs = subprocess.check_output(["git", "ls-remote", "--tags", "https://aomedia.googlesource.com/aom"], text=True)
    aom_tags = []
    for line in refs.splitlines():
        match = re.search(r"refs/tags/(v([0-9]+(?:\.[0-9]+)+))$", line)
        if match: aom_tags.append((tuple(map(int, match.group(2).split('.'))), match.group(1)))
    tag = max(aom_tags)[1]
    url = f"https://storage.googleapis.com/aom-releases/libaom-{version(tag)}.tar.gz"
    sources["libaom"] = {"version": version(tag), "revision": tag, "url": url, "sha256": digest(url), "update": "stable-release"}

    # x264 has no numbered releases. Its upstream-maintained stable branch is the explicit exception.
    project = urllib.parse.quote_plus("videolan/x264")
    branch = request(f"https://code.videolan.org/api/v4/projects/{project}/repository/branches/stable")
    commit = branch["commit"]["id"]
    url = f"https://code.videolan.org/videolan/x264/-/archive/{commit}/x264-{commit}.tar.gz"
    sources["x264"] = {"version": commit[:12], "revision": commit, "url": url, "sha256": digest(url), "update": "upstream-stable-branch"}

    # The foundations updater discovers LAME through SourceForge's stable
    # release metadata. Preserve that selection while refreshing its hash.
    lame = old.get("sources", {}).get("lame", {"version":"3.100", "revision":"3.100", "url":"https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz"})
    lame["sha256"] = digest(lame["url"]); lame.setdefault("update", "manual-stable-release")
    sources["lame"] = lame

    tools = old.get("tools", {})
    if not tools: raise SystemExit("versions.lock must seed pinned Rust and cargo-c versions")
    meson_meta = request("https://pypi.org/pypi/meson/json")
    meson_wheel = next(x for x in meson_meta["urls"] if x["packagetype"] == "bdist_wheel")
    tools["meson"] = {"version": meson_meta["info"]["version"], "url": meson_wheel["url"], "sha256": meson_wheel["digests"]["sha256"]}
    for key in ("rustup_x86_64", "rustup_aarch64"):
        tools[key]["sha256"] = digest(tools[key]["url"])
    result = {"schema": 1, "updated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
              "alpine": old.get("alpine", {"version":"3.20"}), "tools": tools, "sources": dict(sorted(sources.items()))}
    tmp = LOCK + ".tmp"
    with open(tmp, "w") as f: json.dump(result, f, indent=2, sort_keys=False); f.write("\n")
    os.replace(tmp, LOCK)

if __name__ == "__main__": main()
