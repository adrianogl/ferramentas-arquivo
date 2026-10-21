#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ferramentas de Arquivo.app"
APP="$ROOT/build/$APP_NAME"
INSTALLED="/Applications/$APP_NAME"
BUNDLE_ID="dev.aglv.FerramentasArquivo"

cd "$ROOT"
swift build -c release --product FileToolsApp
BIN_DIR="$(swift build -c release --product FileToolsApp --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/FileToolsApp" "$APP/Contents/MacOS/FileTools"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$ROOT/Resources/MenuBarIcon.pdf" "$APP/Contents/Resources/"

IDENTITY="${SIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="$(security find-identity -v -p codesigning | grep -m1 '"Apple Development' | sed -E 's/.*"(.*)"/\1/' || true)"
fi
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="-"
    echo "aviso: assinatura ad hoc: as permissões serão pedidas de novo a cada build" >&2
fi
codesign --force --sign "$IDENTITY" "$APP"
echo "app em $APP (assinado com $IDENTITY)"

if [[ "${1:-}" == "--install" ]]; then
    osascript -e "quit app id \"$BUNDLE_ID\"" || true
    rm -rf "$INSTALLED"
    cp -R "$APP" "$INSTALLED"
    /System/Library/CoreServices/pbs -update
    open "$INSTALLED"
    echo "instalado em $INSTALLED"
fi
