#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
lock_file=versions.lock
dry_run=false

case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

for command in curl jq awk sed shasum mktemp; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 1; }
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/ffmpeg-musl-forge-update.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

get() {
  curl --fail --location --silent --show-error --retry 3 \
    --user-agent ffmpeg-musl-forge-lock-updater "$@"
}

sha256_url() {
  local url=$1 file="$work_dir/download"
  get --output "$file" "$url"
  shasum -a 256 "$file" | awk '{print $1}'
}

alpine_metadata=$(get https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/latest-releases.yaml)
alpine_version=$(awk '$1 == "version:" {print $2; exit}' <<<"$alpine_metadata")
test -n "$alpine_version"

registry_token=$(get 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/alpine:pull' | jq -er .token)
manifest_headers="$work_dir/alpine-headers"
get --head --dump-header "$manifest_headers" --output /dev/null \
  --header "Authorization: Bearer $registry_token" \
  --header 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json' \
  "https://registry-1.docker.io/v2/library/alpine/manifests/$alpine_version"
alpine_digest=$(tr -d '\r' < "$manifest_headers" | awk -F': ' 'tolower($1) == "docker-content-digest" {print $2; exit}')
[[ "$alpine_digest" =~ ^sha256:[0-9a-f]{64}$ ]]

rust_metadata=$(get https://static.rust-lang.org/dist/channel-rust-stable.toml)
rust_version=$(awk '/^\[pkg.rust\]$/ {found=1; next} found && /^version =/ {gsub(/"/, "", $3); print $3; exit}' <<<"$rust_metadata")
[[ "$rust_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

cargo_c_full=$(get https://crates.io/api/v1/crates/cargo-c | jq -er .crate.max_stable_version)
cargo_c_version=${cargo_c_full%%+*}
[[ "$cargo_c_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

lame_metadata=$(get https://sourceforge.net/projects/lame/best_release.json)
lame_path=$(jq -er '.release.filename | select(test("^/lame/[0-9]+(\\.[0-9]+)*/lame-[0-9]+(\\.[0-9]+)*\\.tar\\.gz$"))' <<<"$lame_metadata")
lame_version=$(sed -E 's#^/lame/([^/]+)/.*#\1#' <<<"$lame_path")
lame_url="https://downloads.sourceforge.net/project/lame${lame_path}"
lame_sha256=$(sha256_url "$lame_url")

rustup_x86_url=$(jq -er .tools.rustup_x86_64.url "$lock_file")
rustup_arm_url=$(jq -er .tools.rustup_aarch64.url "$lock_file")
rustup_x86_sha256=$(sha256_url "$rustup_x86_url")
rustup_arm_sha256=$(sha256_url "$rustup_arm_url")

updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
candidate="$work_dir/versions.lock"
jq \
  --arg updated_at "$updated_at" \
  --arg alpine_version "$alpine_version" \
  --arg alpine_digest "$alpine_digest" \
  --arg rust_version "$rust_version" \
  --arg cargo_c_version "$cargo_c_version" \
  --arg rustup_x86_sha256 "$rustup_x86_sha256" \
  --arg rustup_arm_sha256 "$rustup_arm_sha256" \
  --arg lame_version "$lame_version" \
  --arg lame_url "$lame_url" \
  --arg lame_sha256 "$lame_sha256" \
  '.updated_at = $updated_at
   | .alpine = {version: $alpine_version, digest: $alpine_digest}
   | .tools.rust_toolchain.version = $rust_version
   | .tools.cargo_c.version = $cargo_c_version
   | .tools.rustup_x86_64.sha256 = $rustup_x86_sha256
   | .tools.rustup_aarch64.sha256 = $rustup_arm_sha256
   | .sources.lame = {
       version: $lame_version,
       revision: $lame_version,
       url: $lame_url,
       sha256: $lame_sha256,
       update: "stable-release"
     }' "$lock_file" > "$candidate"

echo "Alpine $alpine_version ($alpine_digest)"
echo "Rust $rust_version"
echo "cargo-c $cargo_c_version"
echo "LAME $lame_version ($lame_sha256)"

if $dry_run; then
  diff -u "$lock_file" "$candidate" || true
else
  mv "$candidate" "$lock_file"
  echo "Updated $lock_file; review its diff and rebuild both architectures."
fi
