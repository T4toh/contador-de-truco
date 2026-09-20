#!/bin/bash

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="io.github.t4toh.contadordetruco"

echo "📱 Instalando Contador de Truco en dispositivo Android..."
echo ""

# Verificar si el APK existe
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK no encontrado en $APK_PATH"
    echo "💡 Ejecuta primero: ./build_apk.sh"
    exit 1
fi

# Verificar si hay dispositivos conectados
echo "🔍 Buscando dispositivos conectados..."
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)

if [ $DEVICES -eq 0 ]; then
    echo "❌ No hay dispositivos Android conectados"
    echo "💡 Conecta tu dispositivo con USB y habilita depuración USB"
    exit 1
fi

echo "✅ Dispositivo encontrado"
echo ""

# Mostrar dispositivo conectado
echo "📱 Dispositivo:"
adb devices | grep "device" | head -1

# Desinstalar app anterior (limpiar cache y datos)
echo ""
echo "🧹 Desinstalando versión anterior..."
adb uninstall $PACKAGE_NAME 2>/dev/null
sleep 1

# Instalar APK
echo ""
echo "📲 Instalando APK..."
adb install "$APK_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ App instalada exitosamente!"
    echo "🎯 Puedes abrir 'Contador de Truco' desde tu dispositivo"
    echo ""
    echo "🚀 ¿Quieres abrirla ahora? (s/n)"
    read -r response
    if [ "$response" = "s" ] || [ "$response" = "S" ]; then
        adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1
        echo "✅ App abierta"
    fi
else
    echo ""
    echo "❌ Error al instalar la app"
    exit 1
fi
