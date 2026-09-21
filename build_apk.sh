#!/bin/bash

echo "🔨 Construyendo APK de Pulpero..."
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Construir APK
echo "🚀 Construyendo APK..."
flutter build apk --release

# Verificar si el build fue exitoso
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ APK construido exitosamente!"
    echo "📍 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    ls -lh build/app/outputs/flutter-apk/app-release.apk
else
    echo ""
    echo "❌ Error al construir el APK"
    exit 1
fi
