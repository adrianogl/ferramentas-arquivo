#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "uso: $0 <versão>" >&2
    exit 64
fi

VERSION="$1"
if [[ ! $VERSION =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "uso: $0 <versão>  (ex.: 0.1.0)" >&2
    exit 64
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ferramentas de Arquivo.app"
ZIP="$ROOT/build/Ferramentas-de-Arquivo-$VERSION.zip"
RELEASE_PLIST="$ROOT/build/Info.release.plist"

mkdir -p "$ROOT/build"
cp "$ROOT/Resources/Info.plist" "$RELEASE_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$RELEASE_PLIST"

INFO_PLIST="$RELEASE_PLIST" "$ROOT/scripts/build-app.sh" --adhoc --universal

rm -f "$ZIP" "$ZIP.sha256"
ditto -c -k --keepParent "$ROOT/build/$APP_NAME" "$ZIP"
(cd "$ROOT/build" && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256")

echo "zip em $ZIP"
cat "$ZIP.sha256"
