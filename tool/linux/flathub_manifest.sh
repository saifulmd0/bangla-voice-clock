#!/bin/sh
# Writes the Flathub version of the Flatpak manifest for a published
# release: the same as linux/flatpak/, but with the tarball fetched from
# the GitHub release by URL and checksum.
#
#   tool/linux/flathub_manifest.sh v1.0.0 > io.github.saifulmd0.BanglaVoiceClock.yml
set -eu
cd "$(dirname "$0")/../.."
tag=$1
asset="BanglaVoiceClock-$tag-linux-x64.tar.gz"
url="https://github.com/saifulmd0/bangla-voice-clock/releases/download/$tag/$asset"
sha=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
awk -v url="$url" -v sha="$sha" '
  /^#( |$)/ && !done { next }
  { done = 1 }
  /path: BanglaVoiceClock-linux-x64.tar.gz/ {
    sub(/path: .*/, "url: " url); print
    sub(/url: .*/, "sha256: " sha); print
    sub(/sha256: .*/, "dest-filename: BanglaVoiceClock-linux-x64.tar.gz"); print
    next
  }
  { print }
' linux/flatpak/io.github.saifulmd0.BanglaVoiceClock.yml
