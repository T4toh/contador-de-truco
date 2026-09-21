# 🃏 Contador de Truco

App de **Flutter** para llevar el puntaje de juegos de cartas argentinos. Sin backend, sin cuentas,
sin assets externos: todo se dibuja con widgets nativos de Flutter y `CustomPainter`.

Pensada para apoyar el celular en la mesa y tocar la pantalla mientras se juega.

---

## 🎮 Juegos

| Juego | Estado | Detalle |
| ----- | ------ | ------- |
| **Truco** | ✅ Completo | Partidas a 15 ("a malas") o a 30 ("a buenas"), 2 equipos |
| **Escoba del 15** | ✅ Completo | 2, 3 o 4 jugadores, partida a 15 puntos |
| **Generala** | ⏳ Pendiente | Reglas escritas en `docs/generala.md`, sin implementar |

### Truco

- **A MALAS** = partida a 15 puntos. **A BUENAS** = partida a 30.
- En partidas a 30, al llegar a 15 el equipo pasa de *las malas* a *las buenas*: cambia el color del
  panel, aparece el chip `EN LAS BUENAS` y se dispara una animación de escala.
- Nombres de equipo editables (por defecto `Nosotros` y `Ellos`).

### Escoba del 15

- Partida fija a 15 puntos.
- 2 o 3 jugadores: los paneles se acomodan según la orientación del teléfono.
- 4 jugadores: grilla 2x2 siempre, para que cada uno tenga su esquina de la mesa.
- Nombres de jugador editables (por defecto `Jugador 1`…`Jugador 4`).

---

## 📱 Controles

| Acción | Cómo |
| ------ | ---- |
| Sumar 1 punto | **Tap** en cualquier parte del panel del equipo/jugador |
| Restar 1 punto | Botón **`-`** dentro del panel |
| Renombrar | **Mantener presionado** el nombre |
| Reiniciar partida | Botón 🔄 arriba a la derecha (pide confirmación) |
| Cambiar de juego | Barra de navegación inferior |

Los puntajes están limitados entre 0 y el máximo de la partida: restar nunca da negativo y sumar
nunca pasa del tope.

---

## 🎨 Cómo se ven los puntos

Los puntos se dibujan como **fósforos**, igual que anotando en un papel: cada grupo de 5 es un
cuadrado de 4 fósforos más la diagonal. Está hecho con `CustomPainter` — no hay imágenes en el
proyecto.

El resto de la interfaz sigue el tema "paño y madera": fondo verde de mesa de juego y paneles de
madera, con tipografía **Alegreya** vía `google_fonts`. Es un único tema oscuro fijo — no sigue el
modo claro/oscuro del sistema.

---

## 💾 Persistencia

La partida en curso se guarda sola con `shared_preferences` después de cada cambio: puntajes,
nombres, modo de juego y si hay partida empezada. Si cerrás la app en la mitad de una partida, al
volver seguís donde estabas.

Las claves están prefijadas por juego (`truco_*`, `escoba_*`). `GameStorage` migra los esquemas
viejos (claves sin prefijo de cuando la app tenía un solo juego, y versiones anteriores por juego)
una sola vez al arrancar, antes de que exista cualquier pantalla.

---

## 🚀 Desarrollo

Requiere el **SDK de Flutter** (Dart SDK `^3.9.2`).

```bash
flutter pub get      # instalar dependencias
flutter run          # correr en el dispositivo conectado
flutter analyze      # linter (flutter_lints)
flutter test         # tests de widget
```

### Scripts para Android

```bash
./run_on_device.sh   # verifica que haya un device por adb y corre en modo debug
./build_apk.sh       # clean + pub get + build apk --release
./install_apk.sh     # desinstala la versión anterior e instala el APK release
./release.sh         # valida versión y firma, buildea e imprime el gh release create (no publica)
```

La app se actualiza sola: al abrir consulta la última release de GitHub y, si hay una versión
nueva, ofrece descargarla e instalarla desde un banner.

### Dependencias

`shared_preferences` · `cupertino_icons` · `flutter_lints` (dev). Las tipografías van empaquetadas en `assets/fonts/`.

---

## 📂 Estructura

```
lib/
├── main.dart                        # arranque, migración, navegación por tabs
├── theme/
│   ├── mesa_colors.dart             # paleta paño/madera
│   └── mesa_theme.dart              # ThemeData único (oscuro fijo)
├── games/
│   ├── game_spec.dart               # descripción de un juego como dato
│   ├── score_game.dart              # estado y reglas, sin widgets
│   ├── game_storage.dart            # persistencia + migración de esquemas viejos
│   ├── counter_screen.dart          # pantalla única que renderiza cualquier GameSpec
│   ├── panel_layout.dart            # cómo se acomodan los paneles según orientación/cantidad
│   └── catalog.dart                 # los juegos: Truco y Escoba del 15
└── widgets/
    ├── felt_background.dart         # fondo de paño
    ├── wood_panel.dart              # panel de madera
    ├── score_panel.dart             # panel de puntaje de un equipo/jugador
    ├── game_header.dart             # header con reset
    ├── name_dialog.dart             # diálogo para renombrar
    ├── matchstick_counter.dart      # los fósforos (CustomPainter)
    ├── matchstick_layout.dart       # cálculo de columnas/tamaño de los fósforos
    └── winner_bottom_sheet.dart     # pantalla de ganador
docs/                                # reglas de cada juego (no docs de código)
```

Un juego ya no es un archivo autocontenido: es una entrada (`GameSpec`) en `catalog.dart` — id,
título, ícono, participantes posibles, topes y nombres por defecto. `CounterScreen` es la única
pantalla y renderiza cualquier `GameSpec`; agregar un juego nuevo no toca la UI. El estado y las
reglas viven en `ScoreGame` (sin dependencia de widgets, se testea directo) y la persistencia en
`GameStorage`, con claves prefijadas por `spec.id`. La navegación usa `IndexedStack`, así que cambiar
de tab no pierde la partida del otro juego.

---

## 🛠️ Pendientes conocidos

- **Nombre**: "Contador de Truco" ya quedó chico con Escoba adentro y más juegos en camino.
  Pensar uno mejor antes de que la app circule más.
- **Generala**: las reglas están en `docs/generala.md` pero no hay código. Su planilla de 13 casillas
  no encaja en el patrón "contador de puntos" de los otros dos juegos.
- **Papa**: agregar el juego (reglas y contador).
- **Reglas de todos los juegos**: `docs/` tiene Escoba y Generala; falta `docs/truco.md`, y cada
  juego que se agregue tiene que entrar con sus reglas.
- **Otros juegos**: investigar qué más se juega con dados o con cartas españolas y falta acá
  (chinchón, casita robada, siete y medio, cacho, etc.).
- **Tirador de dados** de todas las caras (D4, D6, D8, D10, D12, D20). Para el final.
- **Tests**: falta cubrir la planilla de ganador y el ida y vuelta completo de persistencia a través
  de la UI. Lo demás está: la lógica de puntaje en `test/score_game_test.dart`, las migraciones en
  `test/game_storage_test.dart`, y tocar, restar y renombrar en `test/counter_screen_test.dart`.

---

## 📋 Plataformas

El proyecto tiene las carpetas de Android, iOS, Linux, macOS, Windows y Web que genera
`flutter create`, pero el único objetivo probado y con scripts propios es **Android**.

---

**¡A jugar! 🎴**
