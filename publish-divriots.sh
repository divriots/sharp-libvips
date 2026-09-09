#!/usr/bin/env bash
# Publish the @divriots/sharp-libvips packages the divriots monorepo overrides,
# from local builds or the CI artifacts:
#   ./build.sh linux-x64 && ./build.sh linux-arm64v8 && ./build.sh darwin-arm64v8
#   ./publish-divriots.sh [--dry-run]
# Packs them as populate-npm-workspace.sh does (lib/index.js, the ./binary
# export sharp >= 0.35 requires), for these platforms only.
set -e
DRY_RUN="${1:-}"
source ./versions.properties
VIPS="${VERSION_VIPS%-[[:alnum:]]*}"

for pair in "linux-x64:linux-x64" "linux-arm64v8:linux-arm64" "darwin-arm64v8:darwin-arm64"; do
  PLATFORM="${pair%%:*}"
  PACKAGE="${pair##*:}"
  TARBALL="sharp-libvips-$PLATFORM.tar.gz"
  [ -f "$TARBALL" ] || { echo "missing $TARBALL — run ./build.sh $PLATFORM"; exit 1; }
  rm -rf "npm/$PACKAGE/include" "npm/$PACKAGE/lib"
  tar xzf "$TARBALL" -C "npm/$PACKAGE"
  echo "module.exports = __dirname;" > "npm/$PACKAGE/lib/index.js"
  rm -r "npm/$PACKAGE/include" "npm/$PACKAGE/THIRD-PARTY-NOTICES.md"
  case "$PACKAGE" in
    darwin*) BINARY="./lib/libvips-cpp.$VIPS.dylib" ;;
    *) BINARY="./lib/libvips-cpp.so.$VIPS" ;;
  esac
  [ -f "npm/$PACKAGE/$BINARY" ] || { echo "missing npm/$PACKAGE/$BINARY"; exit 1; }
  (cd "npm/$PACKAGE" && npm pkg set "exports[./binary]=$BINARY")
  # --tag: npm refuses to publish a prerelease-style version without one.
  (cd "npm/$PACKAGE" && npm publish --access public --tag latest ${DRY_RUN:+--dry-run})
done
