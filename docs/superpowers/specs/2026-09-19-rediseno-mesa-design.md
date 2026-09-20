# Rediseño "Mesa" + modelo reusable de contadores

**Fecha:** 2026-09-19
**Estado:** aprobado, pendiente de plan de implementación

---

## 1. Problema

La app funciona pero es fea, y está estructurada de forma que empeora con cada juego nuevo.

**Lo visual.** No hay ninguna decisión de diseño tomada: es Material 3 crudo. `ColorScheme.fromSeed(Colors.green)` genera una paleta pastel genérica, el fondo es un gradiente de tres containers que se mezclan en un barro de bajo contraste, todo es rectángulo redondeado de radio 20 con borde de 2px, y los fósforos —lo único con carácter— son marrones sobre lavanda.

**Lo estructural.** `truco_counter.dart` (476 líneas) y `escoba_counter.dart` (440) repiten el diálogo de nombre, el header con reset, el gradiente de fondo, el bottom sheet de ganador y la lógica de puntaje. Un cambio visual hay que hacerlo dos veces; con un tercer juego, tres.

**El bug crónico.** Cinco de los últimos siete commits son intentos de arreglar el clipping de los fósforos. La causa es el `FittedBox`: estira un dibujo de tamaño fijo hasta llenar el panel. En tablet eso escala las líneas de 5px a 15px y se ve crudo. El síntoma se parchó cinco veces; la causa sigue ahí.

## 2. Objetivo

Que la app tenga identidad visual propia, que el layout de fósforos deje de romperse y escale bien a tablet, y que agregar un contador nuevo sea cuestión de describirlo con datos en vez de escribir otra pantalla.

## 3. Decisiones

| Decisión | Por qué |
|---|---|
| Seguir en Flutter | El roadmap (dados, animaciones) es justo donde Flutter rinde. Irse a nativo implica reescribir lo que anda y duplicar el trabajo nuevo. |
| Dirección visual "paño y madera" | Materialista y cálida; los dados caen naturales en ella. Elegida sobre "pizarrón de bar" y "neo-retro plano". |
| Alegreya + Alegreya Sans | Serif humanista para nombres y puntajes, sans para UI chica. De Huerta Tipográfica, Buenos Aires: tipografía argentina para juegos argentinos. Ya está `google_fonts`, no suma dependencia. |
| Tema único oscuro | Una mesa de paño verde no tiene versión clara. Mantener light+dark duplica el trabajo de diseño a cambio de nada. |
| `ColorScheme` construido a mano | `fromSeed` es literalmente lo que produjo la paleta que no gusta. |
| Fósforos nivel 2 | Palito con veta y volumen, cabeza con reflejo, sombra, imperfección por fósforo. Salto grande contra lo actual sin construir un motor de animación todavía. |
| Motor de animación diferido | Construirlo ahora, sin dados que lo usen, sería adivinar su forma. Se hace cuando los dados digan qué necesitan. |
| Abstraer el modelo de contador | Con Truco, Escoba y el gallo (Truco de a tres) hay tres casos concretos. Con dos habría sido especular. |

## 4. Alcance

**Entra:** sistema de diseño (tokens, tipografía, tema); widgets compartidos extraídos; modelo declarativo de juego contador; Truco y Escoba migrados a ese modelo; fósforos redibujados y su layout reescrito; animación de entrada del fósforo.

**No entra:** Generala (es una planilla de 13 casillas, no un contador — forzarla rompería el modelo); el tirador de dados; instalar el Android SDK; cambiar el `applicationId`; publicar.

## 5. Arquitectura

```
lib/
├── main.dart
├── theme/
│   ├── mesa_colors.dart
│   └── mesa_theme.dart
├── games/
│   ├── game_spec.dart
│   ├── score_game.dart
│   ├── game_storage.dart
│   ├── counter_screen.dart
│   ├── panel_layout.dart
│   └── catalog.dart
└── widgets/
    ├── felt_background.dart
    ├── wood_panel.dart
    ├── score_panel.dart
    ├── game_header.dart
    ├── name_dialog.dart
    ├── matchstick_counter.dart
    └── winner_bottom_sheet.dart
```

`lib/truco/` y `lib/escoba/` se eliminan: pasan a ser entradas de `catalog.dart`.

### 5.1 `GameSpec` — el juego como dato

Una lista de un solo elemento significa "fijo, no se pregunta". Con más de uno, el setup lo pregunta. Esa es toda la regla; no hacen falta tipos sellados.

```dart
class GameSpec {
  final String id;                      // clave de persistencia y de catálogo
  final String titulo;                  // 'Truco', 'Escoba del 15'
  final IconData icono;
  final List<int> participantes;        // [2] fijo · [2,3,4] se elige
  final List<int> topes;                // [15] fijo · [15,30] se elige
  final Map<int, String>? etiquetasTope; // {15:'A MALAS', 30:'A BUENAS'}
  final List<String> nombresPorDefecto;
  final Hito? hito;
}

class Hito {                            // el "pasa a las buenas"
  final int en;                         // 15
  final int? soloSiTope;                // 30 → solo aplica si el tope elegido es 30
  final String antes;                   // 'EN LAS MALAS'
  final String despues;                 // 'EN LAS BUENAS'
}
```

**Orden del setup:** primero el tope (si hay más de uno), después los participantes. Ese orden no es cosmético: mantiene verdes los tests actuales, que esperan `A MALAS`/`A BUENAS` como primera pantalla de Truco y `¿Cuántos jugadores?` como primera de Escoba.

Etiquetas: el tope usa `etiquetasTope` y, si es null, `'$tope puntos'`. Los participantes usan `'$n jugadores'` — el texto que los tests ya verifican.

`nombresPorDefecto` declara tantos nombres como el máximo de `participantes`; al empezar una partida se toman los primeros N. Debe tener al menos `participantes.last` elementos.

### 5.2 `catalog.dart`

```dart
const truco = GameSpec(
  id: 'truco', titulo: 'Truco', icono: Icons.style,
  participantes: [2], topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(en: 15, soloSiTope: 30, antes: 'EN LAS MALAS', despues: 'EN LAS BUENAS'),
);

const escoba = GameSpec(
  id: 'escoba', titulo: 'Escoba del 15', icono: Icons.grid_view,
  participantes: [2, 3, 4], topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
);
```

Agregar el gallo será una entrada más de ~10 líneas, sin tocar UI. Alternativamente, darle a `truco` `participantes: [2, 3]` lo convierte en una opción dentro de Truco. El modelo aguanta las dos; se decide al agregarlo.

### 5.3 `ScoreGame` — estado y reglas, sin widgets

Clase común, testeable sin `WidgetTester`. La posee el `State` de `CounterScreen`, que envuelve las mutaciones en `setState`. Sin librería de state management.

```dart
class ScoreGame {
  final GameSpec spec;
  int tope;
  List<int> puntajes;
  List<String> nombres;
  bool empezada;
  bool terminada;
  String? ganador;

  void empezar({required int tope, required int participantes});
  void sumar(int indice, int puntos);   // clamp 0..tope; marca ganador al llegar
  void renombrar(int indice, String nombre);
  void reiniciar();
  bool cruzoElHito(int indice);         // alimenta el chip
}
```

`sumar` conserva el comportamiento actual: `clamp(0, tope)` —restar nunca da negativo, sumar nunca pasa el tope— y al alcanzar el tope marca `terminada` y `ganador`.

### 5.4 `panel_layout.dart`

Reemplaza el layout hardcodeado por juego:

```dart
List<List<int>> layoutFor(int cantidad, Orientation orientacion);
```

Devuelve filas de índices. Cubre 2, 3 y 4 conservando lo de hoy: 4 siempre en grilla 2x2 sin importar la orientación; 2 y 3 en columna si es vertical, en fila si es horizontal. Admite 5 y 6 el día que hagan falta, sin tocar juegos.

### 5.5 Fósforos

**El dibujo.** Cada fósforo es un palito con degradé de veta y una banda de brillo, más una cabeza elíptica con volumen y un reflejo chico, con sombra proyectada sobre el paño. El grupo de 5 sigue siendo los cuatro lados de un cuadrado más la diagonal.

**La imperfección.** Ángulo (±2.5°) y largo (±3%) salen de un hash determinístico del índice del fósforo. Determinístico es el requisito: si usara `Random()` sin semilla, los fósforos titilarían en cada redibujo.

**El layout — el fix de fondo.** Se elimina el `FittedBox`. En su lugar, una función pura:

```dart
MatchLayout calcularLayout({
  required int puntos,
  required Size espacio,
  double minGrupo = 44,
  double maxGrupo = 96,
  double separacion = 8,
});

class MatchLayout {
  final double tamanoGrupo;
  final int columnas;
  final int filas;
}
```

Algoritmo: `grupos = (puntos / 5).ceil()`. Se prueban tamaños desde `maxGrupo` bajando de a 4px; para cada uno, `columnas = max(1, (ancho + sep) ~/ (tamaño + sep))` y `filas = (grupos / columnas).ceil()`; se acepta el primero cuyo alto total entre en el espacio. Si ninguno entra, se devuelve `minGrupo` con las columnas que quepan.

El tope máximo de puntaje es 30, o sea 6 grupos: en la práctica siempre entra bastante antes del mínimo. El caso ajustado real es el panel de Escoba con 4 jugadores en celular.

Consecuencia buscada: en celular se ven pocas columnas de fósforos a tamaño normal; en tablet se ven **más fósforos del mismo tamaño real**, en más columnas, como en una hoja más grande. El detalle crece en vez de pixelarse. Y el clipping desaparece por construcción, porque el tamaño sale de medir el espacio, no de estirar un dibujo hasta llenarlo.

**La animación.** Solo el fósforo recién sumado: entra con una caída corta de ~200ms con `Curves.easeOut`, sin rebote. Un `AnimationController` por widget, no uno por fósforo. El pulso al cruzar el hito se conserva más sobrio (1.1 → 1.04).

### 5.6 Sistema de diseño

**Tokens** (`mesa_colors.dart`):

| Token | Valor | Uso |
|---|---|---|
| `panoBase` | `#1D4732` | fondo de mesa |
| `panoLuz` | `#2F6B4A` | centro del degradé radial |
| `panoSombra` | `#143327` | bordes del degradé |
| `maderaClara` | `#7A4F2C` | tope del panel |
| `maderaOscura` | `#5D3A1F` | base del panel |
| `maderaBorde` | `#3D2513` | contorno del panel |
| `crema` | `#F2E3C8` | texto sobre madera |
| `dorado` | `#A8813C` | bordes de acento |
| `doradoClaro` | `#F6D98A` | chip del hito, iconos |
| `brasa` | `#C0392B` | cabezas de fósforo, botón restar |
| `maderaFosforo` | `#DCC294` | palito |

**Tipografía** (`mesa_theme.dart`): `GoogleFonts.alegreya` para nombres y puntajes, `GoogleFonts.alegreyaSans` para UI chica y botones. Un solo `TextTheme` definido en el tema; se eliminan las llamadas sueltas a `GoogleFonts.raleway()` repartidas por los widgets.

**Tema**: un único `ThemeData` con `ColorScheme` construido campo por campo desde los tokens. Se eliminan `darkTheme` y `themeMode`.

**Widgets**: `FeltBackground` (paño con textura por `CustomPainter`), `WoodPanel` (madera con sombra, borde y veta), `ScorePanel` (nombre + chip + fósforos + puntaje + botón restar), `GameHeader` y `NameDialog` (hoy duplicados en ambos counters).

### 5.7 Persistencia y migración

Esquema unificado, prefijado por `spec.id`: `<id>_tope`, `<id>_empezada`, `<id>_participantes`, `<id>_score_$i`, `<id>_name_$i`.

Una clave `schema_version` hace que la migración corra una sola vez. Hay que cubrir **tres** orígenes:

1. **Legacy sin prefijo** (`scoreA`, `gameStarted`, …) — ya lo migra el código actual a `truco_*`. Ese paso se conserva tal cual.
2. **Truco v1** — `truco_scoreA`/`truco_scoreB` → `truco_score_0`/`truco_score_1`; `truco_teamAName`/`truco_teamBName` → `truco_name_0`/`truco_name_1`; `truco_maxScore` → `truco_tope`; `truco_gameStarted` → `truco_empezada`; se escribe `truco_participantes = 2`.
3. **Escoba v1** — `escoba_playerCount` → `escoba_participantes`; `escoba_gameStarted` → `escoba_empezada`; se escribe `escoba_tope = 15`. Las claves `escoba_score_$i` y `escoba_name_$i` ya coinciden con el esquema nuevo.

Un error acá le borra la partida en curso a quien actualice, así que la migración va cubierta por tests.

## 6. Testing

**Los 3 tests actuales tienen que seguir pasando sin modificarse.** Eso fija estos textos: `Truco`, `Escoba del 15`, `A MALAS`, `A BUENAS`, `¿Cuántos jugadores?`, `2 jugadores`, `3 jugadores`, `4 jugadores`.

Tests nuevos:

- **`calcularLayout`** (el que más falta hace — es la lógica que se rompió cinco veces): panel chico de celular con 4 jugadores; panel de tablet; puntaje máximo de 30; que el tamaño devuelto nunca salga de `[minGrupo, maxGrupo]`; que el alto total nunca exceda el espacio salvo en el caso degradado del mínimo.
- **`ScoreGame`**: clamp en 0 al restar de más; clamp en el tope al sumar de más; detección de ganador exactamente al llegar al tope; `cruzoElHito` verdadero desde 15 solo cuando el tope es 30.
- **Migración**: partiendo de claves v1 de Truco y de Escoba, que el juego cargado conserve puntajes y nombres.

## 7. Verificación visual

`flutter run -d web-server`, abrir en Firefox, redimensionar la ventana para simular celular y tablet. No hace falta el Android SDK (no está instalado, ni `adb`), y redimensionar la ventana es justamente la prueba de tablet.

Entorno ya verificado: Flutter 3.47.4 stable (Dart 3.13.3), `flutter analyze` limpio, `flutter test` 3/3 en verde.

## 8. Riesgos

| Riesgo | Mitigación |
|---|---|
| La migración pierde partidas guardadas | Tests de migración desde ambos esquemas v1; `schema_version` para no correrla dos veces. |
| Verificar solo en web oculta diferencias con Android | Las diferencias esperadas son menores (sombras, hinting de fuentes). Revisar en dispositivo real antes de dar el rediseño por cerrado. |
| `google_fonts` descarga la fuente en runtime; sin red cae al fallback | Ya pasa hoy con Raleway. Si molesta, empaquetar Alegreya como asset — fuera de alcance de esta tanda. |
| La abstracción no aguanta el cuarto juego | Aceptado. Está dimensionada para tres casos reales, no para todos los imaginables. Generala queda explícitamente afuera. |

## 9. Orden sugerido

1. Tema y tokens (`theme/`), con la app compilando contra el tema nuevo.
2. Widgets compartidos extraídos, sin cambiar todavía el aspecto.
3. `GameSpec` + `ScoreGame` + `GameStorage` + migración, con sus tests.
4. `CounterScreen` + `panel_layout`; Truco y Escoba pasan a ser entradas del catálogo; se borran `lib/truco/` y `lib/escoba/`.
5. Fósforos: `calcularLayout` con sus tests, después el dibujo nuevo.
6. Animación de entrada.
7. Repaso visual en celular y tablet.

El plan detallado sale de este documento como paso siguiente.
