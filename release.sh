#!/bin/bash
# Prepara un release: valida versión y firma, buildea el APK e imprime el
# comando de publicación. NO publica: el tag lo crea una persona.
set -euo pipefail

cd "$(dirname "$0")"

TMPDIR_ERR=$(mktemp)
trap 'rm -f "$TMPDIR_ERR"' EXIT

if ! gh auth status >/dev/null 2>&1; then
    echo "❌ gh no está autenticado (gh auth login). Sin eso no se pueden verificar el tag ni el versionCode publicado."
    exit 1
fi

VERSION_COMPLETA=$(grep '^version:' pubspec.yaml | awk '{print $2}') || true   # 1.0.1+3
VERSION=${VERSION_COMPLETA%%+*}                                          # 1.0.1
BUILD=${VERSION_COMPLETA##*+}                                            # 3
TAG="v$VERSION"

if [ "$VERSION_COMPLETA" = "$VERSION" ]; then
    echo "❌ pubspec.yaml no tiene build number (esperaba X.Y.Z+N, hay $VERSION_COMPLETA)"
    exit 1
fi

if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then
    echo "❌ El build number de pubspec.yaml no es un número: '$BUILD'"
    exit 1
fi

if ! grep -q "^## \[$VERSION\]" CHANGELOG.md; then
    echo "❌ CHANGELOG.md no tiene la sección '## [$VERSION] - AAAA-MM-DD'."
    echo "   Renombrá '## [Sin publicar]' con la versión y la fecha, y agregá el link al pie."
    exit 1
fi

if [ ! -f android/key.properties ]; then
    echo "❌ Falta android/key.properties: el APK saldría firmado con el keystore de debug"
    echo "   y Android lo rechazaría como actualización (INSTALL_FAILED_UPDATE_INCOMPATIBLE)."
    exit 1
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || gh release view "$TAG" >/dev/null 2>&1; then
    echo "❌ El tag $TAG ya existe. Subí version: en pubspec.yaml."
    exit 1
fi

# El updater compara la versión semver, pero Android compara el versionCode:
# si no sube, el instalador rechaza el APK aunque el tag sea mayor.
set +e
BUILD_PUBLICADO=$(gh release download --pattern versionCode.txt -O - 2>"$TMPDIR_ERR")
DESCARGA_OK=$?
set -e
if [ "$DESCARGA_OK" -ne 0 ]; then
    if grep -q "no assets match" "$TMPDIR_ERR"; then
        echo "⚠️  El último release no tiene versionCode.txt: no se puede verificar el bump del versionCode."
        BUILD_PUBLICADO=""
    else
        echo "❌ No se pudo consultar el último release:"
        cat "$TMPDIR_ERR"
        exit 1
    fi
fi
BUILD_PUBLICADO=$(echo "$BUILD_PUBLICADO" | tr -d '[:space:]')
if [ -n "$BUILD_PUBLICADO" ]; then
    if ! [[ "$BUILD_PUBLICADO" =~ ^[0-9]+$ ]]; then
        echo "❌ versionCode.txt del último release no es un número: '$BUILD_PUBLICADO'"
        exit 1
    fi
    if [ "$BUILD" -le "$BUILD_PUBLICADO" ]; then
        echo "❌ versionCode $BUILD no es mayor que el publicado ($BUILD_PUBLICADO). Subí el +N en pubspec.yaml."
        exit 1
    fi
fi

./build_apk.sh

SALIDA=build/app/outputs/flutter-apk
APK="$SALIDA/pulpero-$VERSION.apk"
cp "$SALIDA/app-release.apk" "$APK"
echo "$BUILD" > "$SALIDA/versionCode.txt"
shasum -a 256 "$APK"

echo ""
echo "✅ Listo. Para publicar $TAG, corré vos:"
echo ""
echo "  gh release create $TAG \"$APK\" \"$SALIDA/versionCode.txt\" --title $TAG --generate-notes"
echo ""
