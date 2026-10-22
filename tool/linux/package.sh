#!/bin/sh
# Packages `flutter build linux --release` as
#   BanglaVoiceClock-linux-x64.tar.gz  the app folder plus its desktop entry,
#                                      metainfo and icons under share/ (what
#                                      the Flatpak repackages), and
#   BanglaVoiceClock-linux-amd64.deb   for Ubuntu, Debian and Mint.
#
#   tool/linux/package.sh [out-dir]
set -eu
cd "$(dirname "$0")/../.."
out=${1:-.}
id=io.github.saifulmd0.BanglaVoiceClock
bundle=build/linux/x64/release/bundle
version=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The tarball: bangla-voice-clock/{bangla-voice-clock,lib,data,share}.
app="$work/bangla-voice-clock"
mkdir -p "$app"
cp -a "$bundle"/. "$app"/
install -Dm644 "linux/packaging/$id.desktop" "$app/share/applications/$id.desktop"
install -Dm644 "linux/packaging/$id.metainfo.xml" "$app/share/metainfo/$id.metainfo.xml"
cp -a linux/packaging/icons "$app/share/"
install -Dm644 LICENSE "$app/share/doc/bangla-voice-clock/LICENSE"
install -Dm644 NOTICE.md "$app/share/doc/bangla-voice-clock/NOTICE.md"
tar -C "$work" --owner=0 --group=0 --numeric-owner -czf "$out/BanglaVoiceClock-linux-x64.tar.gz" bangla-voice-clock

# The .deb: the app in /opt, a command in /usr/bin, the rest in /usr/share.
deb="$work/deb"
mkdir -p "$deb/opt" "$deb/usr/bin" "$deb/usr/share" "$deb/DEBIAN"
cp -a "$app" "$deb/opt/bangla-voice-clock"
mv "$deb/opt/bangla-voice-clock/share"/* "$deb/usr/share/"
rmdir "$deb/opt/bangla-voice-clock/share"
ln -s /opt/bangla-voice-clock/bangla-voice-clock "$deb/usr/bin/bangla-voice-clock"
size=$(du -sk "$deb/opt" "$deb/usr" | awk '{s += $1} END {print s}')
cat > "$deb/DEBIAN/control" <<CONTROL
Package: bangla-voice-clock
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $size
Depends: libgtk-3-0t64 | libgtk-3-0, libayatana-appindicator3-1, libpulse0
Recommends: gnome-shell-extension-appindicator
Maintainer: Saiful Islam <mr.saiful.islam.saif@gmail.com>
Homepage: https://github.com/saifulmd0/bangla-voice-clock
Description: Talking clock that tells the time aloud in Bangla
 Bangla Voice Clock (বাংলা ভয়েস ক্লক) announces the time in natural Bangla,
 the way it is said in Bangladesh, every 15, 30 or 60 minutes. It sits in the
 panel, has two voices, quiet hours, a talking timer, and a Bangla or English
 window in light or dark.
CONTROL
dpkg-deb --build --root-owner-group "$deb" "$out/BanglaVoiceClock-linux-amd64.deb"
ls -l "$out"/BanglaVoiceClock-linux-*
