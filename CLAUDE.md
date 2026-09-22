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
./release.sh                         # valida versión y firma, buildea e imprime el gh release create (no publica)
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

## Updater

La app se actualiza sola desde GitHub Releases: `lib/update/` consulta
`releases/latest` al abrir (como mucho una vez cada 24 h, gate en
`SharedPreferences` bajo `update_last_check`), y si el tag es un semver mayor que el
`versionName` instalado muestra `UpdateBanner` arriba del tablero. Al tocar
"Actualizar", `UpdaterPlugin.kt` descarga el `.apk` con `DownloadManager`, verifica el
SHA-256 contra el `digest` que expone la API de GitHub y lanza el instalador.

- **Tags:** `v<version>` (`v1.0.1`), la parte de `pubspec.yaml` antes del `+`. Android
  compara el `versionCode` (el `+N`), así que hay que subir los dos. `release.sh` verifica
  el bump contra el asset `versionCode.txt` del release anterior.
- **Assets del release:** el `.apk` (único asset que termina en `.apk`; el updater toma
  el primero) y `versionCode.txt`.
- **Permisos:** el manifest declara `INTERNET` y `REQUEST_INSTALL_PACKAGES`. En Xiaomi la
  primera vez el banner manda a Ajustes ("Instalar apps desconocidas"); al volver a la
  app arranca solo.
- **Firma:** un APK firmado con otro keystore lo rechaza el instalador de Android
  (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`); la app no puede preverlo. Ver [Firma](#firma).
- **Sin red o API caída:** silencio, `debugPrint` y reintento al día siguiente. Nunca un
  diálogo al abrir.
- El chequeo corre desde `HomeScreen`, nunca desde `main()`.

## Changelog

`CHANGELOG.md` (Keep a Changelog, en español) es un asset: la app lo muestra en un bottom sheet
al tocar la versión en el setup, y sola la primera vez que arranca una versión distinta a la
última vista (`Novedades`, clave `ultima_version_vista`; en instalación limpia no muestra nada).
`lib/changelog/changelog.dart` es el parser mínimo: `## [versión] - fecha`, `### subtítulo`,
`- viñeta` con continuación indentada; lo demás se ignora. Sin paquete de markdown.

**Cada feature o fix que entra a main se anota en `## [Sin publicar]`** (crearla arriba de la
última versión si no existe; no dejarla vacía, el sheet la mostraría sin contenido). Al publicar, esa
sección se renombra `## [X.Y.Z] - AAAA-MM-DD` y se agrega el link al pie; `release.sh` corta si
la sección de la versión no existe.

## Arquitectura

App Flutter de contadores de puntaje para juegos de cartas argentinos. Sin backend, sin state
management externo: todo `StatefulWidget` + `setState` + `CustomPainter`. Los únicos assets son las
tipografías (`assets/fonts/`); `assets/icon/pulpero.png` es la fuente del launcher icon, no se
empaqueta. Los `mipmap-*` (adaptive en `mipmap-anydpi-v26`, fondo crema en `values/colors.xml`) se
regeneran desde ahí con ImageMagick: alpha = oscuridad del dibujo, arte al 66% para el adaptive y al
80% para el legacy.

**Shell** — `lib/main.dart`: `main()` corre la migración de `GameStorage` una sola vez, antes de
`runApp`, envuelta en `try/catch` (si falla, se pierde la partida vieja pero la app abre igual —
nunca dejar que un fallo de migración tire una pantalla en blanco). Después, `ContadorDeTrucoApp`
(tema único vía `mesaTheme()`) → `HomeScreen` con `NavigationBar` + `IndexedStack`. El `IndexedStack`
es intencional: mantiene vivo el estado de cada juego al cambiar de tab.

**Un juego = una entrada de `lib/games/catalog.dart`.** `catalogo` es una `List<Juego>`: título,
ícono y un constructor de pantalla. Los contadores (Truco, Escoba) se describen con un `GameSpec`
(`lib/games/game_spec.dart`, puro dato: id, participantes, topes, nombres, `Hito` opcional) y se
envuelven con `Juego.contador(spec)`, que monta `CounterScreen`. Un juego con otro modelo trae su
pantalla: Generala es `lib/generala/` entero (`Casilla`/`Jugada` en `reglas.dart`, `GeneralaGame`,
`GeneralaStorage` con un JSON bajo `generala_partida`, `GeneralaScreen` + `Planilla` +
`JugadaSheet`). No pasa por `GameStorage` ni por `schema_version`.

**`CounterScreen`** (`lib/games/counter_screen.dart`) es la pantalla de los contadores (Truco,
Escoba), para cualquier `GameSpec`: recibe el spec y decide solo qué preguntar en el setup (tope si
`spec.eligeTope`, cantidad de participantes si `spec.eligeParticipantes`) y cómo se acomodan los
paneles (`panel_layout.dart`, según orientación y cantidad). Ciclo de vida: `_juego.empezada ==
false` → setup → `_empezar` → vista de partida (`GameHeader` + tablero) → al llegar al tope,
`terminada = true` + `WinnerBottomSheet` no dismissible → "Nueva partida" vuelve al setup.

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
- `FeltBackground` / `WoodPanel` — fondo de paño y panel de madera, la base visual del tema. La
  trama del paño es una **textura repetida** (tile de 6×6 vía `ImageShader`), no líneas por frame:
  dibujar ~600 líneas con alpha en cada frame dejaba la Redmi Pad SE en ~40 ms por frame, e Impeller
  no cachea capas, así que `RepaintBoundary` solo no alcanza. **No volver a `drawLine` en el paint.**
- `ScorePanel` — panel de un equipo/jugador: nombre, puntaje, chip de hito, botones +/-. Las franjas
  del botón `−` y del puntaje se dimensionan como fracción del ancho del panel (con `clamp`), no
  fijas: con 64 + 96 px fijos, un panel de la grilla 2x2 en teléfono se quedaba sin lugar para los
  fósforos y desbordaba. Si el panel es angosto y el nombre sigue siendo el de fábrica, se muestra
  `spec.nombresCortos` (`J#1`); un nombre puesto por el usuario no se abrevia nunca.
- `GameHeader` — título de la partida + botón de reinicio.
- `NameDialog` — diálogo para renombrar.
- `SetupChoice` — pantalla de setup con botones grandes; la usan `CounterScreen` y `GeneralaScreen`.
- `MatchstickCounter` — dibuja el puntaje como fósforos (`CustomPainter`): grupos de 5, 4 lados de un
  cuadrado más la diagonal.
- `WinnerBottomSheet` — pantalla de ganador, recibe `onReset`; `titulo` opcional reemplaza el "¡GANÓ
  `<nombre>`!" por defecto (Generala lo usa para el empate).
- `UpdateBanner` — aviso de versión nueva; orquesta permiso → descarga → SHA-256 → instalador.

## Reglas de juego codificadas

- **Truco** (`catalog.dart`): tope 15 ("A MALAS") o 30 ("A BUENAS"), 2 participantes fijos. Con tope
  30, el `Hito` dispara en 15: cambia el aspecto del panel y el chip pasa de `EN LAS MALAS` a
  `EN LAS BUENAS` (`ScoreGame.cruzoElHito`). Nombres por defecto `Nosotros` / `Ellos`.
- **Escoba del 15**: tope fijo 15, 2 a 4 participantes. Con 4, `panel_layout.dart` arma grilla 2x2
  si el tablero tiene alto para dos filas (`altoDisponible >= altoMinimoPanel * 2`); si no —landscape
  de teléfono— los pone en una sola fila, porque con la grilla cada panel quedaba en ~78 px y el
  puntaje, los fósforos y el botón `−` desaparecían clipeados. Con 2 o 3 depende de la orientación
  (`layoutFor`).
- Los puntajes se hacen `.clamp(0, tope)` en `ScoreGame.sumar`, así que restar nunca va a negativo ni
  sumar pasa del tope.
- **Generala** (`lib/generala/reglas.dart`): reglamento Ruibal, citado en el comentario del enum.
  Once casillas; números cantidad × número; escalera 20, full 30, póker 40, +5 servidos; generala
  60; generala doble 100; cualquier generala servida termina la partida. Empate en el total =
  varios `ganadores`. `Casilla.opciones` es la única tabla de puntajes: cambiar una regla es tocar
  ahí. `Casilla.simbolo` es la etiqueta de la tabla (caras de dado y E/F/P/G/G2, como en la
  planilla de papel).

## Convenciones de UI

- Interacción: **tap** en el panel = +1, **long-press** sobre el nombre = renombrar, botón `-` = -1
  (deshabilitado cuando `_juego.terminada`); contadores: Truco y Escoba. En Generala, tap en la
  celda abre las fichas y no hay botón `-`; long-press en el nombre renombra en los tres juegos, y
  en Generala también el tap sobre el nombre.
- Todo el texto de la UI está en español rioplatense ("Ingresá el nombre", "¿Reiniciar partida?").
- Colores: fuera de un `CustomPainter`, siempre una constante de `MesaColors` (nunca
  `Theme.of(context).colorScheme` ni `Colors.*` directo) — ver `lib/theme/mesa_colors.dart`. Dentro de
  un `CustomPainter` (los fósforos), el sombreado procedural queda literal (`Colors.white.withValues`,
  gradientes con `Color(0x...)` puntuales) porque ahí se está simulando luz, no pintando UI.
- Tipografía: `mesaTheme()` define un único `textTheme` (Alegreya / Alegreya Sans) y el resto del
  código usa `Theme.of(context).textTheme.<estilo>` — no hay `TextStyle(fontFamily: ...)` suelto
  repartido por los widgets. Las fuentes van **empaquetadas** en `assets/fonts/`, declaradas en la
  sección `fonts:` de `pubspec.yaml`. **No volver a `google_fonts`**: baja las fuentes de
  `fonts.googleapis.com` en runtime, y el APK de release no tiene permiso de `INTERNET` —Flutter
  solo lo declara en los manifiestos de `debug` y `profile`—, así que la descarga fallaba en
  silencio y la app en release se veía entera en Roboto. Los `.ttf` son OFL; las licencias están en
  `assets/fonts/OFL-*.txt`.
- `mesaTheme()` fuerza `splashFactory: InkRipple.splashFactory`: el `InkSparkle` que Material 3 usa
  por defecto pinta con el fragment shader `shaders/ink_sparkle.frag`, que el runner de
  `flutter test` no puede compilar (el asset del SDK trae solo stages Vulkan y el runner usa SkSL),
  así que cualquier toque en un botón tiraba una excepción en los tests. **No sacar esa línea.**
- Los diálogos usan `RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))` (vía
  `dialogTheme` en `mesaTheme()`).
- `main()` pone `SystemUiMode.edgeToEdge` y barras del sistema transparentes sin contraste
  forzado: sin eso Android pinta la barra de gestos con un fondo gris que corta el paño (se veía
  en la Redmi Pad SE). La `NavigationBar` ya respeta el padding inferior; no agregar `SafeArea`
  abajo del Scaffold.

## docs/

`docs/*.md` son las reglas completas de cada juego, no documentación de código. Generala sigue el
reglamento de Ruibal, con el link al PDF en el doc; cualquier otra variante se descarta a propósito.
