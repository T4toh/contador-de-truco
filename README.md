# 🃏 Pulpero

App de **Flutter** para llevar el puntaje de juegos de cartas argentinos. Sin backend, sin cuentas,
sin assets externos: todo se dibuja con widgets nativos de Flutter y `CustomPainter`.

Pensada para apoyar el celular en la mesa y tocar la pantalla mientras se juega.

---

## 🎮 Juegos

| Juego | Estado | Detalle |
| ----- | ------ | ------- |
| **Truco** | ✅ Completo | Partidas a 15 ("a malas") o a 30 ("a buenas"), 2 equipos |
| **Escoba del 15** | ✅ Completo | 2, 3 o 4 jugadores, partida a 15 puntos |
| **Generala** | ✅ Completo | 2 a 6 jugadores, planilla de 11 casillas, reglamento Ruibal |

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

### Generala

- Tocá una celda para cargarla: la app ofrece solo los valores válidos de esa casilla (tachar,
  20 o 25 servida, etc.). Tocar una celda cargada permite corregir o borrar.
- Tocá el nombre (o mantenelo apretado) para renombrar.
- Puntaje según el [reglamento de Ruibal](https://ruibalgames.com/wp-content/uploads/2015/11/Reglamento-Generala.pdf):
  generala 60, generala doble 100, cualquiera de las dos servida gana la partida. Sin bonus por
  números.
- La planilla usa las caras de dado (⚀ a ⚅) y E, F, P, G, G2 como en la de papel.

---

## 📱 Controles

Vale para Truco y Escoba. Generala se carga tocando la celda, ver [Generala](#generala).

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

En Truco y Escoba (Generala es una planilla, no un puntaje que sube). Los puntos se dibujan como
**fósforos**, igual que anotando en un papel: cada grupo de 5 es un cuadrado de 4 fósforos más la
diagonal. Está hecho con `CustomPainter` — no hay imágenes en el proyecto.

El resto de la interfaz sigue el tema "paño y madera": fondo verde de mesa de juego y paneles de
madera, con tipografía **Alegreya** empaquetada en `assets/fonts/`. Es un único tema oscuro fijo — no
sigue el modo claro/oscuro del sistema.

---

## 💾 Persistencia

La partida en curso se guarda sola con `shared_preferences` después de cada cambio: puntajes,
nombres, modo de juego y si hay partida empezada. Si cerrás la app en la mitad de una partida, al
volver seguís donde estabas.

Las claves de Truco y Escoba están prefijadas por juego (`truco_*`, `escoba_*`). `GameStorage` migra
los esquemas viejos (claves sin prefijo de cuando la app tenía un solo juego, y versiones anteriores
por juego) una sola vez al arrancar, antes de que exista cualquier pantalla. Generala guarda su
partida aparte, como un único JSON bajo la clave `generala_partida`, y no pasa por `GameStorage` ni
por su migración.

---

## 📝 Novedades

`CHANGELOG.md` lleva los cambios por versión. La app lo muestra al tocar la versión en el setup,
y sola la primera vez que abrís una versión nueva.

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
│   └── catalog.dart                 # catálogo de juegos: Truco, Escoba y Generala
├── generala/                        # planilla de Generala: reglas, modelo, persistencia y pantalla propias
│   ├── reglas.dart                  # Casilla/Jugada, la única tabla de puntajes
│   ├── generala_game.dart           # estado y reglas, sin widgets
│   ├── generala_storage.dart        # persistencia como un JSON bajo generala_partida
│   ├── generala_screen.dart         # pantalla (setup + planilla + ganador)
│   ├── planilla.dart                # la tabla de casillas × jugadores
│   └── jugada_sheet.dart            # ficha para elegir el valor al tocar una celda
└── widgets/
    ├── felt_background.dart         # fondo de paño
    ├── wood_panel.dart              # panel de madera
    ├── score_panel.dart             # panel de puntaje de un equipo/jugador
    ├── game_header.dart             # header con reset
    ├── name_dialog.dart             # diálogo para renombrar
    ├── setup_choice.dart            # pantalla de setup con botones grandes
    ├── matchstick_counter.dart      # los fósforos (CustomPainter)
    ├── matchstick_layout.dart       # cálculo de columnas/tamaño de los fósforos
    └── winner_bottom_sheet.dart     # pantalla de ganador
docs/                                # reglas de cada juego (no docs de código)
```

Un juego es una entrada en `catalogo` (`lib/games/catalog.dart`), una `List<Juego>` con título,
ícono y un constructor de pantalla. Truco y Escoba son contadores: se describen como un `GameSpec`
puro dato (id, participantes, topes, nombres por defecto) y comparten `CounterScreen`, la pantalla
única de los contadores. Generala tiene otro modelo — una planilla, no un puntaje que sube — así que
trae su propia pantalla (`lib/generala/`) en vez de un `GameSpec`. El estado y las reglas de los
contadores viven en `ScoreGame` (sin dependencia de widgets, se testea directo) y la persistencia en
`GameStorage`, con claves prefijadas por `spec.id`; Generala tiene su propio modelo y storage. La
navegación usa `IndexedStack`, así que cambiar de tab no pierde la partida de ningún juego.

---

## 🛠️ Pendientes conocidos

- **Papa**: agregar el juego (reglas y contador).
- **Reglas de todos los juegos**: `docs/` tiene Truco, Escoba y Generala; cada juego que se agregue
  tiene que entrar con sus reglas.
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
