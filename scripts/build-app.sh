#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ferramentas de Arquivo.app"
APP="$ROOT/build/$APP_NAME"
INSTALLED="/Applications/$APP_NAME"
BUNDLE_ID="dev.aglv.FerramentasArquivo"

INSTALL=false
ADHOC=false
ARCH_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=true ;;
        --adhoc) ADHOC=true ;;
        --universal) ARCH_FLAGS=(--arch arm64 --arch x86_64) ;;
        *) echo "uso: $0 [--install] [--adhoc] [--universal]" >&2; exit 64 ;;
    esac
done
INFO_PLIST="${INFO_PLIST:-$ROOT/Resources/Info.plist}"

cd "$ROOT"
swift build -c release --product FileToolsApp ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN_DIR="$(swift build -c release --product FileToolsApp ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/FileToolsApp" "$APP/Contents/MacOS/FileTools"
cp "$INFO_PLIST" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$ROOT/Resources/MenuBarIcon.pdf" "$APP/Contents/Resources/"

IDENTITY=""
if [[ "$ADHOC" == false ]]; then
    IDENTITY="${SIGN_IDENTITY:-}"
fi
if [[ -z "$IDENTITY" && "$ADHOC" == false ]]; then
    IDENTITY="$(security find-identity -v -p codesigning | grep -m1 '"Apple Development' | sed -E 's/.*"(.*)"/\1/' || true)"
fi
if [[ -z "$IDENTITY" ]]; then
    IDENTITY="-"
    echo "aviso: assinatura ad hoc: as permissões serão pedidas de novo a cada build" >&2
fi
codesign --force --sign "$IDENTITY" "$APP"
echo "app em $APP (assinado com $IDENTITY, arquiteturas: $(lipo -archs "$APP/Contents/MacOS/FileTools"))"

if [[ "$INSTALL" == true ]]; then
    osascript -e "quit app id \"$BUNDLE_ID\"" || true
    rm -rf "$INSTALLED"
    cp -R "$APP" "$INSTALLED"
    /System/Library/CoreServices/pbs -update
    open "$INSTALLED"
    echo "instalado em $INSTALLED"
fi
