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

El resto de la interfaz usa **Material 3** con esquema de color generado a partir de un verde (mesa
de juego), tipografía **Raleway** vía `google_fonts`, y sigue el tema claro/oscuro del sistema.

---

## 💾 Persistencia

La partida en curso se guarda sola con `shared_preferences` después de cada cambio: puntajes,
nombres, modo de juego y si hay partida empezada. Si cerrás la app en la mitad de una partida, al
volver seguís donde estabas.

Las claves están prefijadas por juego (`truco_*`, `escoba_*`). El código de Truco incluye una
migración de claves viejas sin prefijo, de cuando la app tenía un solo juego.

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
```

### Dependencias

`shared_preferences` · `google_fonts` · `cupertino_icons` · `flutter_lints` (dev)

---

## 📂 Estructura

```
lib/
├── main.dart                        # tema, navegación por tabs
├── truco/truco_counter.dart         # juego completo: estado + persistencia + UI
├── escoba/escoba_counter.dart       # ídem
└── widgets/
    ├── matchstick_counter.dart      # los fósforos (CustomPainter)
    └── winner_bottom_sheet.dart     # pantalla de ganador
docs/                                # reglas de cada juego (no docs de código)
```

Cada juego es un archivo autocontenido con su propio estado (`setState`, sin librería de state
management) y su propia persistencia. La navegación usa `IndexedStack`, así que cambiar de tab no
pierde la partida del otro juego.

---

## 🛠️ Pendientes conocidos

- **Generala**: las reglas están en `docs/generala.md` pero no hay código. Su planilla de 13 casillas
  no encaja en el patrón "contador de puntos" de los otros dos juegos.
- **`applicationId`**: sigue siendo `com.example.contador_de_truco`, el default del template. Hay que
  cambiarlo antes de publicar en Play Store.
- **Tests**: los que hay son de humo (que la app renderice y navegue). Falta cubrir la lógica de
  puntaje: el tope, el piso en 0, el umbral de las buenas y la detección de ganador.
- **Duplicación**: los dos contadores repiten el diálogo de nombre, el header con reset y el gradiente
  de fondo. Vale unificarlos cuando entre un tercer juego.
- **Layout de los fósforos**: es la parte más frágil. Varios commits seguidos fueron arreglos de
  clipping cuando el panel queda chico (pocos píxeles de alto, muchos puntos). Hoy se resuelve con
  `FittedBox`. Probar siempre con puntajes altos y en horizontal antes de dar por buena una
  modificación ahí.

---

## 📋 Plataformas

El proyecto tiene las carpetas de Android, iOS, Linux, macOS, Windows y Web que genera
`flutter create`, pero el único objetivo probado y con scripts propios es **Android**.

---

**¡A jugar! 🎴**
