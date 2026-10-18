#!/usr/bin/env bash
# Apply the /hold + file-delivery patch to @xmanrui/dsh-im@5.0.2.
#
# Usage:
#   bash apply.sh                 # patch the web profile copy
#   DSH_IM_PKG_DIR=/path bash apply.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="${DSH_IM_PKG_DIR:-$HOME/.dsh/profiles/web/node_modules/@xmanrui/dsh-im}"
EXPECTED="5.0.2"
PATCH="$HERE/patches/dsh-im-5.0.2.patch"
DIST="$HERE/dist/lib-index-5.0.2.js"

if [ ! -f "$PKG/package.json" ]; then
  echo "dsh-im not found at $PKG" >&2
  echo "set DSH_IM_PKG_DIR to the installed package directory" >&2
  exit 1
fi

version="$(node -p "require('$PKG/package.json').version")"
if [ "$version" != "$EXPECTED" ]; then
  echo "installed @xmanrui/dsh-im is $version, this patch targets $EXPECTED" >&2
  echo "check the upstream issue (ruben #385) for a newer patch, or rebuild with build/build.mjs" >&2
  exit 1
fi

ts="$(date +%Y%m%d_%H%M%S)"

if grep -q "MAX_TOTAL_IMAGES" "$PKG/src/channels/shared/batch-input.mjs" 2>/dev/null; then
  echo "patch already applied to src/; refreshing the built bundle"
else
  cp -p "$PKG/package.json" "$PKG/package.json.bak_hold_$ts" 2>/dev/null || true
  echo "applying $PATCH"
  patch -p1 --forward -d "$PKG" < "$PATCH"
fi

if [ -f "$PKG/lib/index.js" ]; then
  cp -p "$PKG/lib/index.js" "$PKG/lib/index.js.bak_hold_$ts"
fi
cp -p "$DIST" "$PKG/lib/index.js"

echo
echo "verify bundle checksum:"
(cd "$HERE/dist" && sha256sum -c SHA256SUMS) || {
  echo "bundle checksum mismatch" >&2
  exit 1
}

echo
echo "Done. Restart dsh web to load the patched bundle."
echo "  /hold and POST /api/dsh-im/delivery/files are available afterwards."
