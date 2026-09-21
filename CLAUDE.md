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

Sin Android SDK ni Chrome disponibles, la verificación visual se hace con
`flutter run -d web-server --web-port=8080` y Firefox; redimensionar la ventana simula tablet y
horizontal.

`applicationId`: `io.github.t4toh.contadordetruco`. Se usa el namespace `io.github.<usuario>` porque no hay dominio propio; es la convención habitual para apps sin dominio.

## Firma

El release se firma con un keystore propio, no con el de debug. `android/app/build.gradle.kts` lee
`android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`); si ese archivo no
existe cae a la firma de debug, así que `flutter run --release` sigue andando en un clone limpio —
pero ese APK no sirve para distribuir.

Ni el `.jks` ni `key.properties` están en el repo (`android/.gitignore:12-14`), y el keystore vive
fuera del árbol de trabajo. **Una PC nueva necesita que le copies las dos cosas a mano**: sin eso
firma con el debug keystore de esa máquina, que es distinto al de las demás, y Android rechaza la
instalación con `INSTALL_FAILED_UPDATE_INCOMPATIBLE` — hay que desinstalar, y eso borra las partidas
guardadas.

Perder el keystore o su password es irreversible: no hay forma de volver a firmar una actualización
de una instalación existente.

El `versionCode` sale de `flutter.versionCode`, o sea del `version:` de `pubspec.yaml` (`1.0.0+1`, el
número después del `+`). Android solo acepta actualizar a un `versionCode` mayor, así que hay que
subirlo en cada release.

## Arquitectura

App Flutter de contadores de puntaje para juegos de cartas argentinos. Sin backend, sin state
management externo, sin assets: todo `StatefulWidget` + `setState` + `CustomPainter`.

**Shell** — `lib/main.dart`: `main()` corre la migración de `GameStorage` una sola vez, antes de
`runApp`, envuelta en `try/catch` (si falla, se pierde la partida vieja pero la app abre igual —
nunca dejar que un fallo de migración tire una pantalla en blanco). Después, `ContadorDeTrucoApp`
(tema único vía `mesaTheme()`) → `HomeScreen` con `NavigationBar` + `IndexedStack`. El `IndexedStack`
es intencional: mantiene vivo el estado de cada juego al cambiar de tab.

**Un juego = una entrada de `lib/games/catalog.dart`**, no un archivo ni una pantalla. `GameSpec`
(`lib/games/game_spec.dart`) es puro dato: id (también prefijo de persistencia), título, ícono,
participantes posibles, topes posibles, nombres por defecto y un `Hito` opcional (el "pasa a las
buenas"). Agregar un juego es agregar una `const GameSpec` al catálogo — no hay UI que tocar.

**`CounterScreen`** (`lib/games/counter_screen.dart`) es la única pantalla, para cualquier juego:
recibe un `GameSpec` y decide solo qué preguntar en el setup (tope si `spec.eligeTope`, cantidad de
participantes si `spec.eligeParticipantes`) y cómo se acomodan los paneles (`panel_layout.dart`,
según orientación y cantidad). Ciclo de vida: `_juego.empezada == false` → setup → `_empezar` → vista
de partida (`GameHeader` + tablero) → al llegar al tope, `terminada = true` + `WinnerBottomSheet` no
dismissible → "Nueva partida" vuelve al setup.

**`ScoreGame`** (`lib/games/score_game.dart`) tiene el estado y las reglas — sumar con `.clamp(0,
tope)`, detectar ganador, el hito de las buenas — sin ninguna dependencia de widgets. Por eso se
testea directo, sin `WidgetTester`. Lo posee el `State` de `CounterScreen`, que envuelve cada mutación
en `setState`.

**`GameStorage`** (`lib/games/game_storage.dart`) es dueña de la persistencia: `SharedPreferences` con
claves `<id>_tope`, `<id>_empezada`, `<id>_participantes`, `<id>_score_$i`, `<id>_name_$i`. También
migra los tres esquemas históricos (claves sin prefijo de cuando la app tenía un solo juego, y las
versiones v1 de Truco y Escoba) de forma idempotente, guardando `schema_version`. Esta migración corre
**una sola vez desde `main()`**, deliberadamente: correrla por pantalla (una por `CounterScreen`
montado) las hacía correr en paralelo y podían pisarse entre sí.

**Layout de los fósforos** — `calcularLayout` en `lib/widgets/matchstick_layout.dart` mide el espacio
disponible (`Size`) y elige el tamaño de grupo más grande que entra sin desbordar. Ya no hay
`FittedBox` estirando el dibujo: por eso en tablet aparecen más fósforos del mismo tamaño real en vez
de fósforos gigantes, y por eso se arregló el clipping crónico de versiones anteriores. **No
reintroducir un `FittedBox` u otro estirado a llenar el espacio** — volvería a producir el mismo bug
de clipping.

Hay tres caminos, en este orden:

1. **Eje único** (cuando `gruposPorColumna` es null, o sea todo juego que no sea Truco): todos los
   grupos en una sola fila o en una sola columna, el eje que deje el grupo más grande, por
   aritmética directa. Empate a favor de la fila. Mezclar los dos ejes deja bloques irregulares
   (tres grupos como 2+1) que se leen peor.
2. **`gruposPorColumna` fijo** (Truco, 3): las filas las fija el juego y las columnas salen de la
   división; el tamaño se busca de `maxGrupo` hacia abajo. Las 2 columnas × 3 grupos de una partida
   a 30 son deliberadas, no un layout mezclado por accidente.
3. **Grilla**, solo si ni el mejor eje único llega a `pisoAbsoluto`: reparte en dos ejes para no
   desbordar en espacios muy chicos.

**Widgets compartidos** (`lib/widgets/`):
- `FeltBackground` / `WoodPanel` — fondo de paño y panel de madera, la base visual del tema.
- `ScorePanel` — panel de un equipo/jugador: nombre, puntaje, chip de hito, botones +/-. Las franjas
  del botón `−` y del puntaje se dimensionan como fracción del ancho del panel (con `clamp`), no
  fijas: con 64 + 96 px fijos, un panel de la grilla 2x2 en teléfono se quedaba sin lugar para los
  fósforos y desbordaba. Si el panel es angosto y el nombre sigue siendo el de fábrica, se muestra
  `spec.nombresCortos` (`J#1`); un nombre puesto por el usuario no se abrevia nunca.
- `GameHeader` — título de la partida + botón de reinicio.
- `NameDialog` — diálogo para renombrar.
- `MatchstickCounter` — dibuja el puntaje como fósforos (`CustomPainter`): grupos de 5, 4 lados de un
  cuadrado más la diagonal.
- `WinnerBottomSheet` — pantalla de ganador, recibe `onReset`.

## Reglas de juego codificadas

- **Truco** (`catalog.dart`): tope 15 ("A MALAS") o 30 ("A BUENAS"), 2 participantes fijos. Con tope
  30, el `Hito` dispara en 15: cambia el aspecto del panel y el chip pasa de `EN LAS MALAS` a
  `EN LAS BUENAS` (`ScoreGame.cruzoElHito`). Nombres por defecto `Nosotros` / `Ellos`.
- **Escoba del 15**: tope fijo 15, 2 a 4 participantes. Con 4, `panel_layout.dart` siempre arma grilla
  2x2 sin importar la orientación; con 2 o 3 depende de la orientación (`layoutFor`).
- Los puntajes se hacen `.clamp(0, tope)` en `ScoreGame.sumar`, así que restar nunca va a negativo ni
  sumar pasa del tope.

## Convenciones de UI

- Interacción: **tap** en el panel = +1, **long-press** sobre el nombre = renombrar, botón `-` = -1
  (deshabilitado cuando `_juego.terminada`).
- Todo el texto de la UI está en español rioplatense ("Ingresá el nombre", "¿Reiniciar partida?").
- Colores: fuera de un `CustomPainter`, siempre una constante de `MesaColors` (nunca
  `Theme.of(context).colorScheme` ni `Colors.*` directo) — ver `lib/theme/mesa_colors.dart`. Dentro de
  un `CustomPainter` (los fósforos), el sombreado procedural queda literal (`Colors.white.withValues`,
  gradientes con `Color(0x...)` puntuales) porque ahí se está simulando luz, no pintando UI.
- Tipografía: `mesaTheme()` define un único `textTheme` (Alegreya / Alegreya Sans vía `google_fonts`)
  y el resto del código usa `Theme.of(context).textTheme.<estilo>` — no hay `GoogleFonts.alegreya(...)`
  explícito repartido por los widgets.
- `mesaTheme()` fuerza `splashFactory: InkRipple.splashFactory`: el `InkSparkle` que Material 3 usa
  por defecto pinta con el fragment shader `shaders/ink_sparkle.frag`, que el runner de
  `flutter test` no puede compilar (el asset del SDK trae solo stages Vulkan y el runner usa SkSL),
  así que cualquier toque en un botón tiraba una excepción en los tests. **No sacar esa línea.**
- Los diálogos usan `RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))` (vía
  `dialogTheme` en `mesaTheme()`).

## docs/

`docs/*.md` son las reglas completas de cada juego, no documentación de código. `docs/generala.md`
existe pero Generala **no está implementada** — es el próximo juego candidato, y su planilla de 13
casillas no encaja en el patrón "contador de puntos" actual.
