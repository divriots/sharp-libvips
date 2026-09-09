#!/usr/bin/env bash
# Publish the two @divriots/sharp-libvips packages from local builds:
#   ./build.sh linux-x64 && ./build.sh darwin-arm64v8 && ./publish-divriots.sh [--dry-run]
set -e
DRY_RUN="${1:-}"

for pair in "linux-x64:linux-x64" "darwin-arm64v8:darwin-arm64"; do
  PLATFORM="${pair%%:*}"
  PACKAGE="${pair##*:}"
  TARBALL="sharp-libvips-$PLATFORM.tar.gz"
  [ -f "$TARBALL" ] || { echo "missing $TARBALL — run ./build.sh $PLATFORM"; exit 1; }
  rm -rf "npm/$PACKAGE/include" "npm/$PACKAGE/lib"
  tar xzf "$TARBALL" -C "npm/$PACKAGE"
  echo "module.exports = __dirname;" > "npm/$PACKAGE/lib/index.js"
  rm -r "npm/$PACKAGE/include" "npm/$PACKAGE/THIRD-PARTY-NOTICES.md"
  # --tag: npm refuses to publish a prerelease-style version without one.
  (cd "npm/$PACKAGE" && npm publish --access public --tag latest ${DRY_RUN:+--dry-run})
done
