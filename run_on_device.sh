#!/bin/bash

echo "🚀 Ejecutando Pulpero en modo debug..."
echo ""

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
echo ""

# Ejecutar app en modo debug
echo "🏃 Iniciando app en modo debug (hot reload habilitado)..."
flutter run
