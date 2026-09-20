# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Comandos

```bash
flutter pub get                      # dependencias
flutter run                          # correr (o ./run_on_device.sh: valida adb primero)
flutter analyze                      # lint (flutter_lints via analysis_options.yaml)
flutter test                         # todos los tests
flutter test test/widget_test.dart --plain-name 'Truco tab shows game mode selection'   # un test
./build_apk.sh                       # flutter clean + pub get + build apk --release
./install_apk.sh                     # adb uninstall + install del APK release
```

`applicationId` sigue siendo `com.example.contador_de_truco` (default del template).

## Arquitectura

App Flutter de contadores de puntaje para juegos de cartas argentinos. Sin backend, sin state
management externo, sin assets: todo `StatefulWidget` + `setState` + `CustomPainter`.

**Shell** — `lib/main.dart`: `ContadorDeTrucoApp` (tema Material 3 seed verde, light/dark por sistema,
`GoogleFonts.ralewayTextTheme`) → `HomeScreen` con `NavigationBar` + `IndexedStack`. El `IndexedStack`
es intencional: mantiene vivo el estado de cada juego al cambiar de tab. Agregar un juego = agregar su
widget a `_pages` y un `NavigationDestination`.

**Un juego = un archivo autocontenido** (`lib/truco/truco_counter.dart`, `lib/escoba/escoba_counter.dart`).
Cada uno posee su estado, su persistencia y sus vistas. No hay capa de repositorio ni modelos
compartidos; la duplicación entre los dos counters (diálogo de nombre, header con reset, gradiente,
`_showWinnerDialog`) es deliberada por ahora.

**Ciclo de vida compartido por cada counter**: `_gameStarted == false` → `_buildSetupView` (elegir modo
o cantidad de jugadores) → `_startNewGame` → vista de partida (`OrientationBuilder`, portrait = Column /
landscape = Row) → al llegar al máximo `_gameFinished = true` + `WinnerBottomSheet` no dismissible →
"Nueva Partida" vuelve al setup.

**Persistencia** — `SharedPreferences`, claves planas con prefijo por juego: `truco_*`, `escoba_*`
(los scores/nombres de escoba son `escoba_score_$i` / `escoba_name_$i`, indexados por jugador).
`_saveGame()` se llama después de cada mutación. `_loadGame()` en truco tiene un bloque de migración
de claves viejas sin prefijo (`scoreA`, `gameStarted`, …); no romperlo al editar.

**Widgets compartidos** (`lib/widgets/`):
- `MatchstickCounter` — dibuja el puntaje como fósforos: grupos de 5 (`MatchstickGroupPainter` pinta
  4 lados de un cuadrado + diagonal), `groupsPerRow` controla el wrap, `FittedBox` evita clipping
  cuando el panel es chico. Es el punto sensible de layout del repo: varios commits recientes son
  fixes de clipping acá.
- `WinnerBottomSheet` — pantalla de ganador, recibe `onReset`.

## Reglas de juego codificadas

- **Truco**: "A MALAS" = partida a 15, "A BUENAS" = a 30. Con `_maxScore == 30`, `score >= 15` es
  *en las buenas*: cambia el color del panel y dispara una `ScaleTransition` (elastic, 500ms) una sola
  vez al cruzar el umbral. Dos equipos con nombre editable (default `Nosotros` / `Ellos`).
- **Escoba del 15**: máximo fijo 15, 2–4 jugadores. Con 4 jugadores siempre grid 2x2 sin importar la
  orientación; con 2 o 3 depende de la orientación.
- Los puntajes se hacen `.clamp(0, maxScore)`, así que restar nunca va a negativo.

## Convenciones de UI

- Interacción: **tap** en el panel = +1, **long-press** sobre el nombre = renombrar, botón `-` = -1
  (deshabilitado con `_gameFinished`). El README describe controles viejos (+1/+2/+3, tap para
  renombrar) — el código manda.
- Todo el texto de la UI está en español rioplatense ("Ingresá el nombre", "¿Reiniciar partida?").
- Colores siempre desde `Theme.of(context).colorScheme` (funciona en light y dark). Las únicas
  excepciones son los `Paint` de los fósforos (`Colors.brown[400]`, `Colors.redAccent[700]`).
- Tipografía siempre `GoogleFonts.raleway(...)` explícito en cada `Text` con estilo propio.
- Los `AlertDialog` usan `RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))`.

## docs/

`docs/*.md` son las reglas completas de cada juego, no documentación de código. `docs/generala.md`
existe pero Generala **no está implementada** — es el próximo juego candidato, y su planilla de 13
casillas no encaja en el patrón "contador de puntos" actual.
