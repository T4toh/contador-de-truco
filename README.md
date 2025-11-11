# 🃏 Contador de Truco

Una aplicación Flutter para llevar el conteo de puntos en el juego de cartas argentino **Truco**.

## 🎯 Características

- **Partidas a 15 o 30 puntos**: Selecciona el tipo de partida al inicio
- **Dos equipos configurables**: Nombres personalizables (toca el nombre para editarlo)
- **Gestión de puntos**: Botones para sumar +1, +2, +3 o restar puntos
- **Malas y Buenas**: En partidas a 30 puntos, visualización clara de cuándo un equipo pasa de las malas (0-14) a las buenas (15+)
- **Detección de ganador**: Mensaje automático cuando un equipo alcanza el puntaje máximo
- **Contador visual**: Representación de puntos con "fósforos" tipo pixel art
- **Persistencia**: Los puntos se guardan automáticamente con SharedPreferences
- **Diseño responsivo**: Se adapta a orientación vertical y horizontal sin scroll
- **Animaciones**: Efecto visual cuando se pasa a "las buenas"

## 🎨 Diseño

- Fondo estilo mesa verde degradado
- Colores temáticos que cambian según el estado del juego
- Sin assets externos: todo con widgets nativos de Flutter
- Interfaz minimalista y clara

## 🚀 Cómo usar

1. Clona el repositorio
2. Ejecuta `flutter pub get`
3. Corre la app con `flutter run`

## 📱 Controles

- **Nombres**: Toca el nombre de un equipo para editarlo
- **Puntos**: Usa los botones +1, +2, +3 para sumar, o - para restar
- **Reiniciar**: Botón de reinicio en la esquina superior derecha
- **Nueva partida**: Después de reiniciar, puedes elegir el puntaje nuevamente

## 🧩 Extras implementados

✅ Persistencia con SharedPreferences  
✅ Animación al pasar a "las buenas"  
✅ Contador visual con fósforos  
✅ Diseño completamente responsivo  
✅ Nombres editables  

---

**¡A jugar al Truco!** 🎴
