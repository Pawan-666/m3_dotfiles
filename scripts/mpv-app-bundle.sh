#!/usr/bin/env bash
# Rebuild mpv.app around the Homebrew mpv binary.
#
# The `mpv` formula only installs the CLI binary, and the `mpv` cask
# (stolendata-mpv) was disabled on 2026-09-01 for failing Gatekeeper — so a
# brew upgrade leaves `mpv` working in the terminal but no app bundle for
# Finder "Open With", drag-and-drop or the Dock. This wraps the formula's
# binary in mpv's own upstream bundle skeleton (TOOLS/osxbundle) and registers
# it with LaunchServices under the usual io.mpv bundle id, so existing file
# associations snap back. Re-run after mpv changes version.
#
# Usage: scripts/mpv-app-bundle.sh [install-dir]   (default /Applications)

set -euo pipefail

lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

app_dir="${1:-/Applications}"
app="$app_dir/mpv.app"

mpv_bin="$(brew --prefix mpv)/bin/mpv"
if [[ ! -x $mpv_bin ]]; then
	echo "no mpv binary at $mpv_bin — run: brew install mpv" >&2
	exit 1
fi

version="$("$mpv_bin" --version | sed -n '1s/^mpv v\([^ ]*\).*/\1/p')"
if [[ -z $version ]]; then
	echo "could not parse a version out of \`$mpv_bin --version\`" >&2
	exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> fetching the mpv $version bundle skeleton"
curl -fsSL "https://github.com/mpv-player/mpv/archive/refs/tags/v$version.tar.gz" |
	tar xz -C "$work" "mpv-$version/TOOLS/osxbundle/mpv.app"

staged="$work/mpv.app"
cp -R "$work/mpv-$version/TOOLS/osxbundle/mpv.app" "$staged"
find "$staged" -name .gitkeep -delete

echo "==> bundling $mpv_bin"
install -m 755 "$mpv_bin" "$staged/Contents/MacOS/mpv"
# The skeleton plist ships placeholders that the upstream build fills in.
sed -i '' -e "s/\${VERSION}/$version/" -e "s/\${CATEGORY}/video/" \
	"$staged/Contents/Info.plist"

# Homebrew's binary links against absolute /opt/homebrew dylibs, so nothing
# needs bundling — but the bundle still has to carry a valid signature.
echo "==> signing (ad-hoc)"
codesign --force --sign - "$staged/Contents/MacOS/mpv"
codesign --force --sign - "$staged"

echo "==> installing $app"
mkdir -p "$app_dir"
rm -rf "$app"
ditto "$staged" "$app"
"$lsregister" -f "$app"

echo "done: mpv $version at $app"
