# Rediseño "Mesa" — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Darle a la app identidad visual propia ("paño y madera"), arreglar de raíz el clipping de fósforos para que escale a tablet, y convertir Truco y Escoba en descripciones declarativas para que agregar un contador nuevo sea cuestión de datos.

**Architecture:** Un tema único construido a mano desde tokens reemplaza a `ColorScheme.fromSeed`. Los fósforos pasan a dibujarse con volumen y a medir su espacio con una función pura en vez de estirarse con `FittedBox`. Truco y Escoba se disuelven en un `GameSpec` (dato) + un `ScoreGame` (estado y reglas, testeable sin widgets) + un `CounterScreen` (única pantalla de contador).

**Tech Stack:** Flutter 3.47.4 stable · Dart 3.13.3 · `shared_preferences` 2.5.3 · `google_fonts` 6.3.2 · `flutter_test` · sin dependencias nuevas.

**Spec:** `docs/superpowers/specs/2026-09-19-rediseno-mesa-design.md`

## Global Constraints

- **No agregar dependencias.** Todo se resuelve con Flutter, `shared_preferences` y `google_fonts`, que ya están.
- **Los 3 tests de `test/widget_test.dart` deben seguir pasando sin modificarse.** Eso congela estos textos exactos: `Truco`, `Escoba del 15`, `A MALAS`, `A BUENAS`, `¿Cuántos jugadores?`, `2 jugadores`, `3 jugadores`, `4 jugadores`.
- **Idioma:** todo el texto de UI en español rioplatense (`Ingresá el nombre`, `¿Reiniciar partida?`). Nombres de clases, métodos y variables en español, como ya hace el spec.
- **Colores:** siempre desde `MesaColors` o `Theme.of(context).colorScheme`. Prohibido `ColorScheme.fromSeed` y prohibido hardcodear colores fuera de `mesa_colors.dart`, con una única excepción: los degradés internos del fósforo en `matchstick_counter.dart`.
- **Un solo tema.** No se reintroducen `darkTheme` ni `themeMode`.
- **Determinismo:** la imperfección de los fósforos se deriva por hash del índice. Prohibido `Random()` sin semilla — haría titilar el dibujo en cada repintado.
- **Comandos:** `flutter` está en `~/flutter/bin` y ya en el PATH de zsh. `flutter analyze` debe quedar limpio antes de cada commit.
- **Commits:** sin línea de co-autoría (política de la organización).

---

### Task 1: Tokens y tema Mesa

**Files:**
- Create: `lib/theme/mesa_colors.dart`
- Create: `lib/theme/mesa_theme.dart`
- Modify: `lib/main.dart:15-36` (reemplazar `theme`/`darkTheme`/`themeMode`)
- Test: `test/widget_test.dart` (existente, sin modificar)

**Interfaces:**
- Consumes: nada.
- Produces: `MesaColors` (clase con constantes `Color` estáticas: `panoBase`, `panoLuz`, `panoSombra`, `maderaClara`, `maderaOscura`, `maderaBorde`, `crema`, `dorado`, `doradoClaro`, `brasa`, `maderaFosforo`) y `ThemeData mesaTheme()`.

- [ ] **Step 1: Crear los tokens de color**

`lib/theme/mesa_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// Paleta de la dirección visual "paño y madera".
///
/// Los valores son fijos a propósito: `ColorScheme.fromSeed` fue
/// exactamente lo que produjo la paleta pastel que se está reemplazando.
abstract final class MesaColors {
  /// Fondo de mesa.
  static const panoBase = Color(0xFF1D4732);
  static const panoLuz = Color(0xFF2F6B4A);
  static const panoSombra = Color(0xFF143327);

  /// Paneles de jugador.
  static const maderaClara = Color(0xFF7A4F2C);
  static const maderaOscura = Color(0xFF5D3A1F);
  static const maderaBorde = Color(0xFF3D2513);

  /// Texto sobre madera.
  static const crema = Color(0xFFF2E3C8);

  /// Acentos.
  static const dorado = Color(0xFFA8813C);
  static const doradoClaro = Color(0xFFF6D98A);

  /// Cabezas de fósforo y botón restar.
  static const brasa = Color(0xFFC0392B);

  /// Palito del fósforo.
  static const maderaFosforo = Color(0xFFDCC294);
}
```

- [ ] **Step 2: Crear el tema**

`lib/theme/mesa_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mesa_colors.dart';

/// Tema único de la app. No hay variante clara: una mesa de paño verde
/// no la tiene, y mantener dos duplicaría el trabajo de diseño.
ThemeData mesaTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: MesaColors.doradoClaro,
    onPrimary: MesaColors.maderaBorde,
    primaryContainer: MesaColors.maderaClara,
    onPrimaryContainer: MesaColors.crema,
    secondary: MesaColors.dorado,
    onSecondary: MesaColors.maderaBorde,
    secondaryContainer: MesaColors.maderaOscura,
    onSecondaryContainer: MesaColors.crema,
    tertiary: MesaColors.panoLuz,
    onTertiary: MesaColors.crema,
    tertiaryContainer: MesaColors.panoBase,
    onTertiaryContainer: MesaColors.crema,
    error: MesaColors.brasa,
    onError: MesaColors.crema,
    errorContainer: MesaColors.brasa,
    onErrorContainer: MesaColors.crema,
    surface: MesaColors.panoBase,
    onSurface: MesaColors.crema,
    surfaceContainerHighest: MesaColors.maderaOscura,
    onSurfaceVariant: MesaColors.crema,
    outline: MesaColors.maderaBorde,
    outlineVariant: MesaColors.dorado,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final sans = GoogleFonts.alegreyaSansTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: MesaColors.panoBase,
    textTheme: sans.copyWith(
      // Puntaje grande.
      displaySmall: GoogleFonts.alegreya(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
        height: 1,
      ),
      // Nombre del equipo o jugador.
      headlineMedium: GoogleFonts.alegreya(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
      ),
      // Título del header y de los diálogos.
      titleMedium: GoogleFonts.alegreyaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MesaColors.crema,
      ),
      // Chips y botones.
      labelLarge: GoogleFonts.alegreyaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: MesaColors.crema,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MesaColors.panoSombra,
      indicatorColor: MesaColors.maderaClara,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.alegreyaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MesaColors.crema,
        ),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: MesaColors.doradoClaro),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MesaColors.maderaOscura,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
```

- [ ] **Step 3: Conectarlo en `main.dart`**

En `lib/main.dart`, agregar el import `import 'theme/mesa_theme.dart';` y reemplazar el bloque `theme:` … `themeMode: ThemeMode.system,` completo (líneas 17-34) por:

```dart
      theme: mesaTheme(),
```

Borrar también el import de `google_fonts` de `main.dart` si queda sin uso.

- [ ] **Step 4: Verificar que analiza limpio y los tests siguen verdes**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `+3: All tests passed!`

Si algún test falla acá, es que se cambió un texto que no se debía: revisar Global Constraints.

- [ ] **Step 5: Commit**

```bash
git add lib/theme lib/main.dart
git commit -m "feat(theme): tema Mesa con tokens propios en vez de fromSeed"
```

---

### Task 2: `calcularLayout`, la función que reemplaza al FittedBox

Esta es la lógica que se rompió en cinco commits seguidos. Va primero, es pura, y se testea sin widgets.

**Files:**
- Create: `lib/widgets/matchstick_layout.dart`
- Test: `test/matchstick_layout_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `class MatchLayout { final double tamanoGrupo; final int columnas; final int filas; }` y `MatchLayout calcularLayout({required int puntos, required Size espacio, double minGrupo = 44, double maxGrupo = 96, double separacion = 8, double paso = 4})`.

- [ ] **Step 1: Escribir los tests que fallan**

`test/matchstick_layout_test.dart`:

```dart
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/widgets/matchstick_layout.dart';

void main() {
  test('sin puntos no hay grupos', () {
    final l = calcularLayout(puntos: 0, espacio: const Size(300, 200));
    expect(l.columnas, 0);
    expect(l.filas, 0);
  });

  test('en tablet usa el tamaño máximo y varias columnas', () {
    final l = calcularLayout(puntos: 15, espacio: const Size(600, 400));
    expect(l.tamanoGrupo, 96);
    expect(l.columnas, greaterThanOrEqualTo(3));
    expect(l.filas, 1);
  });

  test('en un panel chico achica el grupo en vez de desbordar', () {
    const espacio = Size(150, 120);
    final l = calcularLayout(puntos: 15, espacio: espacio);
    final alto = l.filas * l.tamanoGrupo + (l.filas - 1) * 8;
    expect(alto, lessThanOrEqualTo(espacio.height));
    expect(l.tamanoGrupo, lessThan(96));
  });

  test('el puntaje máximo de truco entra en un panel de celular', () {
    const espacio = Size(320, 220);
    final l = calcularLayout(puntos: 30, espacio: espacio);
    expect(l.columnas * l.filas, greaterThanOrEqualTo(6));
    final alto = l.filas * l.tamanoGrupo + (l.filas - 1) * 8;
    expect(alto, lessThanOrEqualTo(espacio.height));
  });

  test('el tamaño nunca sale del rango permitido', () {
    for (final ancho in [80.0, 150.0, 320.0, 600.0, 1024.0]) {
      for (final alto in [60.0, 120.0, 220.0, 400.0, 768.0]) {
        for (final puntos in [1, 5, 8, 15, 23, 30]) {
          final l = calcularLayout(puntos: puntos, espacio: Size(ancho, alto));
          expect(l.tamanoGrupo, inInclusiveRange(44, 96),
              reason: 'ancho=$ancho alto=$alto puntos=$puntos');
          expect(l.columnas, greaterThanOrEqualTo(1));
        }
      }
    }
  });

  test('siempre alcanzan las celdas para todos los grupos', () {
    final l = calcularLayout(puntos: 23, espacio: const Size(200, 300));
    expect(l.columnas * l.filas, greaterThanOrEqualTo(5)); // 23 puntos = 5 grupos
  });
}
```

- [ ] **Step 2: Correr los tests para verificar que fallan**

Run: `flutter test test/matchstick_layout_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'contador_de_truco/widgets/matchstick_layout.dart'` o `calcularLayout isn't defined`.

- [ ] **Step 3: Implementar**

`lib/widgets/matchstick_layout.dart`:

```dart
import 'dart:ui' show Size;

/// Resultado de acomodar los grupos de fósforos en el espacio disponible.
class MatchLayout {
  final double tamanoGrupo;
  final int columnas;
  final int filas;

  const MatchLayout({
    required this.tamanoGrupo,
    required this.columnas,
    required this.filas,
  });
}

/// Elige el tamaño de cada grupo de 5 fósforos y cómo se distribuyen.
///
/// A diferencia del `FittedBox` que reemplaza, acá el tamaño sale de medir
/// el espacio, no de estirar un dibujo hasta llenarlo. Por eso en tablet
/// aparecen más fósforos del mismo tamaño real en vez de fósforos gigantes.
MatchLayout calcularLayout({
  required int puntos,
  required Size espacio,
  double minGrupo = 44,
  double maxGrupo = 96,
  double separacion = 8,
  double paso = 4,
}) {
  final grupos = (puntos / 5).ceil();
  if (grupos <= 0) {
    return MatchLayout(tamanoGrupo: minGrupo, columnas: 0, filas: 0);
  }

  for (var tamano = maxGrupo; tamano >= minGrupo; tamano -= paso) {
    final columnas = _columnasPara(tamano, espacio.width, separacion);
    final filas = (grupos / columnas).ceil();
    final alto = filas * tamano + (filas - 1) * separacion;
    if (alto <= espacio.height) {
      return MatchLayout(tamanoGrupo: tamano, columnas: columnas, filas: filas);
    }
  }

  // Caso degradado: ni al mínimo entra a lo alto. Se devuelve el mínimo —
  // con tope 30 (6 grupos) esto no debería ocurrir en pantallas reales.
  final columnas = _columnasPara(minGrupo, espacio.width, separacion);
  return MatchLayout(
    tamanoGrupo: minGrupo,
    columnas: columnas,
    filas: (grupos / columnas).ceil(),
  );
}

int _columnasPara(double tamano, double ancho, double separacion) {
  final cabe = ((ancho + separacion) / (tamano + separacion)).floor();
  return cabe < 1 ? 1 : cabe;
}
```

- [ ] **Step 4: Correr los tests para verificar que pasan**

Run: `flutter test test/matchstick_layout_test.dart`
Expected: PASS — 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/matchstick_layout.dart test/matchstick_layout_test.dart
git commit -m "feat(fosforos): calcula el layout midiendo el espacio disponible"
```

---

### Task 3: Fósforos con volumen

**Files:**
- Rewrite: `lib/widgets/matchstick_counter.dart` (completo, 148 líneas actuales)
- Modify: `lib/truco/truco_counter.dart` (la llamada con `groupsPerRow: 3`)
- Test: `test/widget_test.dart` (existente, sin modificar)

**Interfaces:**
- Consumes: `calcularLayout`, `MatchLayout` (Task 2); `MesaColors` (Task 1).
- Produces: `MatchstickCounter({required int points})` — **el parámetro `groupsPerRow` desaparece**, el layout ahora se calcula. Y `MatchstickGroupPainter({required int count, required int semilla})`.

- [ ] **Step 1: Reescribir el widget y el painter**

`lib/widgets/matchstick_counter.dart` completo:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'matchstick_layout.dart';

/// Dibuja el puntaje como fósforos: grupos de 5 (cuatro lados de un
/// cuadrado más la diagonal), igual que anotando en un papel.
class MatchstickCounter extends StatelessWidget {
  final int points;

  const MatchstickCounter({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points <= 0) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 56,
            color: MesaColors.crema.withValues(alpha: .25),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final layout = calcularLayout(
          puntos: points,
          espacio: Size(restricciones.maxWidth, restricciones.maxHeight),
        );

        final grupos = <Widget>[];
        var restantes = points;
        var indice = 0;
        while (restantes > 0) {
          final enEste = restantes >= 5 ? 5 : restantes;
          grupos.add(SizedBox(
            width: layout.tamanoGrupo,
            height: layout.tamanoGrupo,
            child: CustomPaint(
              painter: MatchstickGroupPainter(count: enEste, semilla: indice),
            ),
          ));
          restantes -= enEste;
          indice++;
        }

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: grupos,
          ),
        );
      },
    );
  }
}

/// Pinta un grupo de hasta 5 fósforos.
class MatchstickGroupPainter extends CustomPainter {
  final int count;

  /// Índice del grupo. Alimenta la imperfección de cada fósforo para que
  /// no parezcan clonados — y es determinística, así que no titila.
  final int semilla;

  const MatchstickGroupPainter({required this.count, required this.semilla});

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide * 0.62;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final arribaIzq = Offset(cx - lado / 2, cy - lado / 2);
    final arribaDer = Offset(cx + lado / 2, cy - lado / 2);
    final abajoIzq = Offset(cx - lado / 2, cy + lado / 2);
    final abajoDer = Offset(cx + lado / 2, cy + lado / 2);

    // Orden de colocación: izquierda, arriba, derecha, abajo, diagonal.
    // El primer punto de cada par es donde va la cabeza.
    final trazos = <List<Offset>>[
      [abajoIzq, arribaIzq],
      [arribaIzq, arribaDer],
      [arribaDer, abajoDer],
      [abajoDer, abajoIzq],
      [abajoIzq, arribaDer],
    ];

    for (var i = 0; i < count && i < trazos.length; i++) {
      _fosforo(canvas, trazos[i][0], trazos[i][1], size, i);
    }
  }

  void _fosforo(Canvas canvas, Offset desde, Offset hasta, Size size, int i) {
    final base = size.shortestSide;
    final grosor = base * 0.075;
    final cabezaR = grosor * 1.15;

    final dx = hasta.dx - desde.dx;
    final dy = hasta.dy - desde.dy;
    // ±2.5° de inclinación y ±3% de largo, por fósforo.
    final angulo = math.atan2(dy, dx) + _ruido(i, 0) * 0.045;
    final largo = math.sqrt(dx * dx + dy * dy) * (1 + _ruido(i, 1) * 0.03);

    canvas.save();
    canvas.translate(desde.dx, desde.dy);
    canvas.rotate(angulo);

    final rect = Rect.fromLTWH(cabezaR * 0.4, -grosor / 2, largo, grosor);
    final palito = RRect.fromRectAndRadius(rect, Radius.circular(grosor / 2));

    // Sombra sobre el paño.
    canvas.drawRRect(
      palito.shift(Offset(grosor * 0.25, grosor * 0.45)),
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, grosor * 0.35),
    );

    // Palito con veta.
    canvas.drawRRect(
      palito,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0DCB4),
            MesaColors.maderaFosforo,
            Color(0xFFB9995F),
          ],
          stops: [0, .45, 1],
        ).createShader(rect),
    );

    // Banda de brillo en el canto superior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabezaR * 0.4, -grosor / 2, largo, grosor * 0.28),
        Radius.circular(grosor * 0.14),
      ),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );

    // Cabeza.
    final cabeza = Rect.fromCircle(center: Offset.zero, radius: cabezaR);
    canvas.drawOval(
      cabeza,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Color(0xFFEF6B4A), Color(0xFFCF3A22), Color(0xFF7D1D0F)],
          stops: [0, .5, 1],
        ).createShader(cabeza),
    );

    // Reflejo.
    canvas.drawCircle(
      Offset(-cabezaR * 0.3, -cabezaR * 0.35),
      cabezaR * 0.26,
      Paint()..color = Colors.white.withValues(alpha: .42),
    );

    canvas.restore();
  }

  /// Ruido determinístico en [-1, 1] a partir del grupo, el fósforo y el
  /// canal pedido. Determinístico es el requisito: con `Random()` sin
  /// semilla los fósforos se moverían en cada repintado.
  double _ruido(int indice, int canal) {
    final h = (semilla * 73856093) ^ (indice * 19349663) ^ (canal * 83492791);
    return ((h & 0xFFFF) / 0xFFFF) * 2 - 1;
  }

  @override
  bool shouldRepaint(covariant MatchstickGroupPainter anterior) =>
      anterior.count != count || anterior.semilla != semilla;
}
```

- [ ] **Step 2: Actualizar la llamada que pasaba `groupsPerRow`**

En `lib/truco/truco_counter.dart`, buscar `MatchstickCounter(points: score, groupsPerRow: 3)` y dejarlo en:

```dart
MatchstickCounter(points: score),
```

(La llamada de `escoba_counter.dart` ya usa `MatchstickCounter(points: score)` y no se toca.)

- [ ] **Step 3: Verificar que compila, analiza limpio y los tests pasan**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `+3: All tests passed!`

- [ ] **Step 4: Mirarlo con ojos**

Run: `flutter run -d web-server --web-port=8080`
Abrir `http://localhost:8080` en Firefox, empezar una partida de Truco a 30, sumar hasta 12 puntos. Achicar la ventana a ~400px de ancho (celular) y agrandarla a ~1100px (tablet).
Expected: los fósforos tienen volumen y sombra, no están todos en el mismo ángulo, **no se recortan en ningún tamaño**, y al agrandar la ventana aparecen más columnas en vez de fósforos más gordos.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/matchstick_counter.dart lib/truco/truco_counter.dart
git commit -m "feat(fosforos): dibujo con volumen y layout medido, sin FittedBox"
```

---

### Task 4: Caída del fósforo nuevo

**Files:**
- Modify: `lib/widgets/matchstick_counter.dart` (`MatchstickCounter` pasa a `StatefulWidget`; el painter recibe dos parámetros más)
- Test: `test/widget_test.dart` (existente, sin modificar)

**Interfaces:**
- Consumes: todo lo de Task 3.
- Produces: `MatchstickGroupPainter({required int count, required int semilla, bool animarUltimo = false, double progreso = 1})`. La firma pública de `MatchstickCounter` no cambia.

- [ ] **Step 1: Convertir el contador en `StatefulWidget` con un controlador**

Reemplazar la clase `MatchstickCounter` de `lib/widgets/matchstick_counter.dart` por:

```dart
class MatchstickCounter extends StatefulWidget {
  final int points;

  const MatchstickCounter({super.key, required this.points});

  @override
  State<MatchstickCounter> createState() => _MatchstickCounterState();
}

class _MatchstickCounterState extends State<MatchstickCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _caida = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(MatchstickCounter anterior) {
    super.didUpdateWidget(anterior);
    // Solo al sumar. Al restar o reiniciar, el dibujo cambia sin animación.
    if (widget.points > anterior.points) {
      _caida.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _caida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points <= 0) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 56,
            color: MesaColors.crema.withValues(alpha: .25),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final layout = calcularLayout(
          puntos: widget.points,
          espacio: Size(restricciones.maxWidth, restricciones.maxHeight),
        );

        final cantidadGrupos = (widget.points / 5).ceil();

        return AnimatedBuilder(
          animation: _caida,
          builder: (context, _) {
            final progreso = Curves.easeOut.transform(_caida.value);
            final grupos = <Widget>[];
            var restantes = widget.points;
            var indice = 0;
            while (restantes > 0) {
              final enEste = restantes >= 5 ? 5 : restantes;
              grupos.add(SizedBox(
                width: layout.tamanoGrupo,
                height: layout.tamanoGrupo,
                child: CustomPaint(
                  painter: MatchstickGroupPainter(
                    count: enEste,
                    semilla: indice,
                    animarUltimo: indice == cantidadGrupos - 1,
                    progreso: progreso,
                  ),
                ),
              ));
              restantes -= enEste;
              indice++;
            }

            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: grupos,
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Que el painter dibuje la caída**

En `MatchstickGroupPainter`, agregar los dos campos al constructor:

```dart
  final bool animarUltimo;
  final double progreso;

  const MatchstickGroupPainter({
    required this.count,
    required this.semilla,
    this.animarUltimo = false,
    this.progreso = 1,
  });
```

Dentro de `paint`, reemplazar el cuerpo del `for` por:

```dart
    for (var i = 0; i < count && i < trazos.length; i++) {
      final esElNuevo = animarUltimo && i == count - 1;
      if (esElNuevo && progreso < 1) {
        // Cae desde un poco más arriba, apareciendo.
        canvas.saveLayer(
          Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: progreso),
        );
        canvas.translate(0, -(1 - progreso) * size.shortestSide * 0.18);
        _fosforo(canvas, trazos[i][0], trazos[i][1], size, i);
        canvas.restore();
      } else {
        _fosforo(canvas, trazos[i][0], trazos[i][1], size, i);
      }
    }
```

Y actualizar `shouldRepaint`:

```dart
  @override
  bool shouldRepaint(covariant MatchstickGroupPainter anterior) =>
      anterior.count != count ||
      anterior.semilla != semilla ||
      anterior.animarUltimo != animarUltimo ||
      anterior.progreso != progreso;
```

- [ ] **Step 3: Bajar el pulso del hito**

En `lib/truco/truco_counter.dart`, en el `Tween` de `_scaleAnimation`, cambiar `end: 1.1` por `end: 1.04`.

(Este archivo se borra en Task 9; el pulso definitivo vive en `WoodPanel`, Task 8. El cambio acá es para que el valor sea el mismo mientras las dos implementaciones conviven.)

- [ ] **Step 4: Verificar**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `+3: All tests passed!`

- [ ] **Step 5: Mirarlo con ojos**

Run: `flutter run -d web-server --web-port=8080`
Tocar un panel para sumar.
Expected: el fósforo nuevo entra cayendo unos pocos píxeles en ~200ms, sin rebote. Los que ya estaban no se mueven.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/matchstick_counter.dart lib/truco/truco_counter.dart
git commit -m "feat(fosforos): el fósforo nuevo entra con una caída corta"
```

---

### Task 5: `GameSpec` y `ScoreGame`

**Files:**
- Create: `lib/games/game_spec.dart`
- Create: `lib/games/score_game.dart`
- Test: `test/score_game_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces:
  - `GameSpec({required String id, required String titulo, required IconData icono, required List<int> participantes, required List<int> topes, Map<int,String>? etiquetasTope, required List<String> nombresPorDefecto, Hito? hito})` con `bool get eligeTope`, `bool get eligeParticipantes`, `String etiquetaTope(int)`.
  - `Hito({required int en, int? soloSiTope, required String antes, required String despues})`.
  - `ScoreGame` con `ScoreGame.nueva(GameSpec)`, campos `tope`, `puntajes`, `nombres`, `empezada`, `terminada`, `ganador`, getters `participantes` y `muestraHito`, y métodos `empezar({required int tope, required int participantes})`, `sumar(int indice, int puntos)`, `renombrar(int indice, String nombre)`, `reiniciar()`, `cruzoElHito(int indice)`.

- [ ] **Step 1: Escribir los tests que fallan**

`test/score_game_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/games/game_spec.dart';
import 'package:contador_de_truco/games/score_game.dart';

const specTruco = GameSpec(
  id: 'truco',
  titulo: 'Truco',
  icono: Icons.style,
  participantes: [2],
  topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(
    en: 15,
    soloSiTope: 30,
    antes: 'EN LAS MALAS',
    despues: 'EN LAS BUENAS',
  ),
);

const specEscoba = GameSpec(
  id: 'escoba',
  titulo: 'Escoba del 15',
  icono: Icons.grid_view,
  participantes: [2, 3, 4],
  topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
);

void main() {
  test('empezar toma los primeros N nombres por defecto', () {
    final g = ScoreGame.nueva(specEscoba)..empezar(tope: 15, participantes: 3);
    expect(g.nombres, ['Jugador 1', 'Jugador 2', 'Jugador 3']);
    expect(g.puntajes, [0, 0, 0]);
    expect(g.empezada, isTrue);
  });

  test('restar de más no baja de cero', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 2);
    g.sumar(0, -5);
    expect(g.puntajes[0], 0);
  });

  test('sumar de más no pasa del tope', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 99);
    expect(g.puntajes[0], 15);
  });

  test('al llegar al tope termina y registra el ganador', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.renombrar(1, 'Los Pibes');
    g.sumar(1, 15);
    expect(g.terminada, isTrue);
    expect(g.ganador, 'Los Pibes');
  });

  test('terminada ignora sumas posteriores', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 15);
    g.sumar(1, 3);
    expect(g.puntajes[1], 0);
  });

  test('el hito se cruza a los 15 cuando el tope es 30', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 14);
    expect(g.cruzoElHito(0), isFalse);
    g.sumar(0, 1);
    expect(g.cruzoElHito(0), isTrue);
    expect(g.muestraHito, isTrue);
  });

  test('sin hito o con tope 15 el hito no se muestra', () {
    final truco15 = ScoreGame.nueva(specTruco)
      ..empezar(tope: 15, participantes: 2);
    expect(truco15.muestraHito, isFalse);

    final escoba = ScoreGame.nueva(specEscoba)
      ..empezar(tope: 15, participantes: 2);
    expect(escoba.muestraHito, isFalse);
    expect(escoba.cruzoElHito(0), isFalse);
  });

  test('reiniciar limpia puntajes pero conserva nombres', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, 'Los Pibes');
    g.sumar(0, 7);
    g.reiniciar();
    expect(g.puntajes, [0, 0]);
    expect(g.nombres[0], 'Los Pibes');
    expect(g.terminada, isFalse);
    expect(g.ganador, isNull);
  });

  test('renombrar con texto vacío no pisa el nombre', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, '');
    expect(g.nombres[0], 'Nosotros');
  });

  test('el spec sabe qué preguntar en el setup', () {
    expect(specTruco.eligeTope, isTrue);
    expect(specTruco.eligeParticipantes, isFalse);
    expect(specTruco.etiquetaTope(30), 'A BUENAS');
    expect(specEscoba.eligeTope, isFalse);
    expect(specEscoba.eligeParticipantes, isTrue);
    expect(specEscoba.etiquetaTope(15), '15 puntos');
  });
}
```

- [ ] **Step 2: Correr los tests para verificar que fallan**

Run: `flutter test test/score_game_test.dart`
Expected: FAIL — no existen `game_spec.dart` ni `score_game.dart`.

- [ ] **Step 3: Implementar `GameSpec`**

`lib/games/game_spec.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Un juego contador descrito como dato.
///
/// Una lista de un solo elemento significa "fijo, no se pregunta". Con más
/// de uno, el setup lo pregunta. Esa es toda la regla.
class GameSpec {
  /// Prefijo de las claves de persistencia y clave del catálogo.
  final String id;
  final String titulo;
  final IconData icono;
  final List<int> participantes;
  final List<int> topes;

  /// Cómo se presenta cada tope en el setup. Si es null, "$tope puntos".
  final Map<int, String>? etiquetasTope;

  /// Debe tener al menos `participantes.last` elementos: al empezar una
  /// partida se toman los primeros N.
  final List<String> nombresPorDefecto;

  final Hito? hito;

  const GameSpec({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.participantes,
    required this.topes,
    this.etiquetasTope,
    required this.nombresPorDefecto,
    this.hito,
  });

  bool get eligeTope => topes.length > 1;
  bool get eligeParticipantes => participantes.length > 1;

  String etiquetaTope(int tope) => etiquetasTope?[tope] ?? '$tope puntos';
}

/// El "pasa a las buenas": un umbral intermedio que cambia el aspecto del
/// panel sin terminar la partida.
class Hito {
  final int en;

  /// Si no es null, el hito solo aplica cuando el tope elegido es este.
  final int? soloSiTope;

  final String antes;
  final String despues;

  const Hito({
    required this.en,
    this.soloSiTope,
    required this.antes,
    required this.despues,
  });
}
```

- [ ] **Step 4: Implementar `ScoreGame`**

`lib/games/score_game.dart`:

```dart
import 'game_spec.dart';

/// Estado y reglas de una partida. Sin widgets: se testea directo.
///
/// Lo posee el State de CounterScreen, que envuelve las mutaciones en
/// setState. No hay librería de state management.
class ScoreGame {
  final GameSpec spec;

  int tope;
  List<int> puntajes;
  List<String> nombres;
  bool empezada;
  bool terminada;
  String? ganador;

  ScoreGame({
    required this.spec,
    required this.tope,
    required this.puntajes,
    required this.nombres,
    this.empezada = false,
    this.terminada = false,
    this.ganador,
  });

  factory ScoreGame.nueva(GameSpec spec) {
    final cuantos = spec.participantes.first;
    return ScoreGame(
      spec: spec,
      tope: spec.topes.first,
      puntajes: List.filled(cuantos, 0),
      nombres: spec.nombresPorDefecto.take(cuantos).toList(),
    );
  }

  int get participantes => puntajes.length;

  void empezar({required int tope, required int participantes}) {
    this.tope = tope;
    puntajes = List.filled(participantes, 0);
    nombres = spec.nombresPorDefecto.take(participantes).toList();
    empezada = true;
    terminada = false;
    ganador = null;
  }

  void sumar(int indice, int puntos) {
    if (terminada) return;
    puntajes[indice] = (puntajes[indice] + puntos).clamp(0, tope);
    if (puntajes[indice] >= tope) {
      terminada = true;
      ganador = nombres[indice];
    }
  }

  void renombrar(int indice, String nombre) {
    if (nombre.isEmpty) return;
    nombres[indice] = nombre;
  }

  void reiniciar() {
    puntajes = List.filled(participantes, 0);
    terminada = false;
    ganador = null;
  }

  /// Si este juego muestra el chip del hito con el tope elegido.
  bool get muestraHito {
    final h = spec.hito;
    return h != null && (h.soloSiTope == null || h.soloSiTope == tope);
  }

  bool cruzoElHito(int indice) {
    final h = spec.hito;
    if (h == null || !muestraHito) return false;
    return puntajes[indice] >= h.en;
  }
}
```

- [ ] **Step 5: Correr los tests para verificar que pasan**

Run: `flutter test test/score_game_test.dart`
Expected: PASS — 10 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/games/game_spec.dart lib/games/score_game.dart test/score_game_test.dart
git commit -m "feat(games): el juego como dato y las reglas sin widgets"
```

---

### Task 6: Persistencia unificada y migración

Un error acá le borra la partida en curso a quien actualice. Por eso va con tests antes que código.

**Files:**
- Create: `lib/games/game_storage.dart`
- Test: `test/game_storage_test.dart`

**Interfaces:**
- Consumes: `GameSpec`, `ScoreGame` (Task 5).
- Produces: `GameStorage()` con `Future<void> migrar()`, `Future<void> guardar(ScoreGame)`, `Future<ScoreGame> cargar(GameSpec)`.

Esquema nuevo: `<id>_tope`, `<id>_empezada`, `<id>_participantes`, `<id>_score_$i`, `<id>_name_$i`. La clave `schema_version` evita que la migración corra dos veces.

- [ ] **Step 1: Escribir los tests que fallan**

`test/game_storage_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/games/game_spec.dart';
import 'package:contador_de_truco/games/game_storage.dart';

const specTruco = GameSpec(
  id: 'truco',
  titulo: 'Truco',
  icono: Icons.style,
  participantes: [2],
  topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(
    en: 15,
    soloSiTope: 30,
    antes: 'EN LAS MALAS',
    despues: 'EN LAS BUENAS',
  ),
);

const specEscoba = GameSpec(
  id: 'escoba',
  titulo: 'Escoba del 15',
  icono: Icons.grid_view,
  participantes: [2, 3, 4],
  topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migra una partida de Truco guardada con el esquema viejo', () async {
    SharedPreferences.setMockInitialValues({
      'truco_scoreA': 7,
      'truco_scoreB': 22,
      'truco_maxScore': 30,
      'truco_teamAName': 'Los Pibes',
      'truco_teamBName': 'Ellos',
      'truco_gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.puntajes, [7, 22]);
    expect(g.nombres, ['Los Pibes', 'Ellos']);
    expect(g.tope, 30);
    expect(g.empezada, isTrue);
  });

  test('migra una partida de Escoba guardada con el esquema viejo', () async {
    SharedPreferences.setMockInitialValues({
      'escoba_playerCount': 3,
      'escoba_gameStarted': true,
      'escoba_score_0': 4,
      'escoba_score_1': 11,
      'escoba_score_2': 0,
      'escoba_name_0': 'Tato',
      'escoba_name_1': 'Jugador 2',
      'escoba_name_2': 'Jugador 3',
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specEscoba);

    expect(g.puntajes, [4, 11, 0]);
    expect(g.nombres[0], 'Tato');
    expect(g.tope, 15);
    expect(g.empezada, isTrue);
  });

  test('migra el esquema legacy sin prefijo', () async {
    SharedPreferences.setMockInitialValues({
      'scoreA': 3,
      'scoreB': 9,
      'maxScore': 15,
      'teamAName': 'Nosotros',
      'teamBName': 'Los Otros',
      'gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.puntajes, [3, 9]);
    expect(g.nombres[1], 'Los Otros');
    expect(g.tope, 15);
  });

  test('sin nada guardado devuelve una partida nueva sin empezar', () async {
    SharedPreferences.setMockInitialValues({});

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.empezada, isFalse);
    expect(g.puntajes, [0, 0]);
    expect(g.nombres, ['Nosotros', 'Ellos']);
  });

  test('guardar y cargar da la vuelta completa', () async {
    SharedPreferences.setMockInitialValues({});

    final storage = GameStorage();
    final g = await storage.cargar(specEscoba);
    g.empezar(tope: 15, participantes: 4);
    g.renombrar(2, 'Colo');
    g.sumar(2, 6);
    await storage.guardar(g);

    final leido = await storage.cargar(specEscoba);
    expect(leido.puntajes, [0, 0, 6, 0]);
    expect(leido.nombres[2], 'Colo');
    expect(leido.empezada, isTrue);
  });

  test('la migración no corre dos veces', () async {
    SharedPreferences.setMockInitialValues({
      'truco_scoreA': 5,
      'truco_scoreB': 0,
      'truco_maxScore': 15,
      'truco_teamAName': 'Nosotros',
      'truco_teamBName': 'Ellos',
      'truco_gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();

    final g = await storage.cargar(specTruco);
    g.sumar(0, 3); // queda en 8
    await storage.guardar(g);

    await storage.migrar(); // no debe pisar con el valor viejo
    final otra = await storage.cargar(specTruco);
    expect(otra.puntajes[0], 8);
  });
}
```

- [ ] **Step 2: Correr los tests para verificar que fallan**

Run: `flutter test test/game_storage_test.dart`
Expected: FAIL — no existe `game_storage.dart`.

- [ ] **Step 3: Implementar**

`lib/games/game_storage.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'game_spec.dart';
import 'score_game.dart';

/// Guarda y lee partidas, y migra los esquemas viejos.
///
/// Esquema actual, prefijado por `spec.id`:
///   <id>_tope · <id>_empezada · <id>_participantes
///   <id>_score_$i · <id>_name_$i
class GameStorage {
  static const _claveVersion = 'schema_version';
  static const _versionActual = 2;

  /// Lleva lo guardado al esquema actual. Idempotente.
  Future<void> migrar() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_claveVersion) ?? 0) >= _versionActual) return;

    await _migrarLegacySinPrefijo(prefs);
    await _migrarTrucoV1(prefs);
    await _migrarEscobaV1(prefs);

    await prefs.setInt(_claveVersion, _versionActual);
  }

  /// v0: claves sin prefijo, de cuando la app tenía un solo juego.
  Future<void> _migrarLegacySinPrefijo(SharedPreferences prefs) async {
    if (!prefs.containsKey('gameStarted')) return;

    await prefs.setInt('truco_scoreA', prefs.getInt('scoreA') ?? 0);
    await prefs.setInt('truco_scoreB', prefs.getInt('scoreB') ?? 0);
    await prefs.setInt('truco_maxScore', prefs.getInt('maxScore') ?? 30);
    await prefs.setString(
        'truco_teamAName', prefs.getString('teamAName') ?? 'Nosotros');
    await prefs.setString(
        'truco_teamBName', prefs.getString('teamBName') ?? 'Ellos');
    await prefs.setBool(
        'truco_gameStarted', prefs.getBool('gameStarted') ?? false);

    for (final k in [
      'scoreA',
      'scoreB',
      'maxScore',
      'teamAName',
      'teamBName',
      'gameStarted',
    ]) {
      await prefs.remove(k);
    }
  }

  /// v1 de Truco: dos equipos A/B con nombres propios.
  Future<void> _migrarTrucoV1(SharedPreferences prefs) async {
    if (!prefs.containsKey('truco_gameStarted')) return;

    await prefs.setInt('truco_score_0', prefs.getInt('truco_scoreA') ?? 0);
    await prefs.setInt('truco_score_1', prefs.getInt('truco_scoreB') ?? 0);
    await prefs.setString(
        'truco_name_0', prefs.getString('truco_teamAName') ?? 'Nosotros');
    await prefs.setString(
        'truco_name_1', prefs.getString('truco_teamBName') ?? 'Ellos');
    await prefs.setInt('truco_tope', prefs.getInt('truco_maxScore') ?? 30);
    await prefs.setBool(
        'truco_empezada', prefs.getBool('truco_gameStarted') ?? false);
    await prefs.setInt('truco_participantes', 2);

    for (final k in [
      'truco_scoreA',
      'truco_scoreB',
      'truco_maxScore',
      'truco_teamAName',
      'truco_teamBName',
      'truco_gameStarted',
    ]) {
      await prefs.remove(k);
    }
  }

  /// v1 de Escoba: score_$i y name_$i ya coinciden; cambian los otros.
  Future<void> _migrarEscobaV1(SharedPreferences prefs) async {
    if (!prefs.containsKey('escoba_gameStarted')) return;

    await prefs.setInt(
        'escoba_participantes', prefs.getInt('escoba_playerCount') ?? 2);
    await prefs.setBool(
        'escoba_empezada', prefs.getBool('escoba_gameStarted') ?? false);
    await prefs.setInt('escoba_tope', 15);

    for (final k in ['escoba_playerCount', 'escoba_gameStarted']) {
      await prefs.remove(k);
    }
  }

  Future<void> guardar(ScoreGame juego) async {
    final prefs = await SharedPreferences.getInstance();
    final id = juego.spec.id;

    await prefs.setInt('${id}_tope', juego.tope);
    await prefs.setBool('${id}_empezada', juego.empezada);
    await prefs.setInt('${id}_participantes', juego.participantes);
    for (var i = 0; i < juego.participantes; i++) {
      await prefs.setInt('${id}_score_$i', juego.puntajes[i]);
      await prefs.setString('${id}_name_$i', juego.nombres[i]);
    }
  }

  Future<ScoreGame> cargar(GameSpec spec) async {
    final prefs = await SharedPreferences.getInstance();
    final id = spec.id;

    final cuantos =
        prefs.getInt('${id}_participantes') ?? spec.participantes.first;
    final nombresBase = spec.nombresPorDefecto.take(cuantos).toList();

    return ScoreGame(
      spec: spec,
      tope: prefs.getInt('${id}_tope') ?? spec.topes.first,
      empezada: prefs.getBool('${id}_empezada') ?? false,
      puntajes: List.generate(
        cuantos,
        (i) => prefs.getInt('${id}_score_$i') ?? 0,
      ),
      nombres: List.generate(
        cuantos,
        (i) => prefs.getString('${id}_name_$i') ?? nombresBase[i],
      ),
    );
  }
}
```

- [ ] **Step 4: Correr los tests para verificar que pasan**

Run: `flutter test test/game_storage_test.dart`
Expected: PASS — 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/games/game_storage.dart test/game_storage_test.dart
git commit -m "feat(games): persistencia unificada con migración de los tres esquemas"
```

---

### Task 7: `layoutFor` — cómo se acomodan N paneles

**Files:**
- Create: `lib/games/panel_layout.dart`
- Test: `test/panel_layout_test.dart`

**Interfaces:**
- Consumes: nada (solo `Orientation` de Flutter).
- Produces: `List<List<int>> layoutFor(int cantidad, Orientation orientacion)` — devuelve filas de índices de participante.

- [ ] **Step 1: Escribir los tests que fallan**

`test/panel_layout_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/games/panel_layout.dart';

void main() {
  test('dos jugadores: apilados en vertical, lado a lado en horizontal', () {
    expect(layoutFor(2, Orientation.portrait), [
      [0],
      [1],
    ]);
    expect(layoutFor(2, Orientation.landscape), [
      [0, 1],
    ]);
  });

  test('tres jugadores siguen la orientación', () {
    expect(layoutFor(3, Orientation.portrait), [
      [0],
      [1],
      [2],
    ]);
    expect(layoutFor(3, Orientation.landscape), [
      [0, 1, 2],
    ]);
  });

  test('cuatro jugadores: grilla 2x2 en cualquier orientación', () {
    const grilla = [
      [0, 1],
      [2, 3],
    ];
    expect(layoutFor(4, Orientation.portrait), grilla);
    expect(layoutFor(4, Orientation.landscape), grilla);
  });

  test('cinco y seis se parten en dos filas', () {
    expect(layoutFor(5, Orientation.portrait), [
      [0, 1, 2],
      [3, 4],
    ]);
    expect(layoutFor(6, Orientation.landscape), [
      [0, 1, 2],
      [3, 4, 5],
    ]);
  });

  test('todos los índices aparecen exactamente una vez', () {
    for (final cantidad in [2, 3, 4, 5, 6]) {
      for (final o in Orientation.values) {
        final planos = layoutFor(cantidad, o).expand((f) => f).toList()..sort();
        expect(planos, List.generate(cantidad, (i) => i),
            reason: 'cantidad=$cantidad orientacion=$o');
      }
    }
  });
}
```

- [ ] **Step 2: Correr los tests para verificar que fallan**

Run: `flutter test test/panel_layout_test.dart`
Expected: FAIL — no existe `panel_layout.dart`.

- [ ] **Step 3: Implementar**

`lib/games/panel_layout.dart`:

```dart
import 'package:flutter/widgets.dart' show Orientation;

/// Cómo se acomodan los paneles de N participantes.
///
/// Devuelve filas de índices: `[[0,1],[2,3]]` es una grilla 2x2.
/// Reemplaza el layout que antes estaba hardcodeado en cada juego.
List<List<int>> layoutFor(int cantidad, Orientation orientacion) {
  // Cuatro van siempre en grilla, así cada uno tiene su esquina de la mesa.
  if (cantidad == 4) {
    return [
      [0, 1],
      [2, 3],
    ];
  }

  if (cantidad >= 5) {
    final primera = (cantidad / 2).ceil();
    return [
      List.generate(primera, (i) => i),
      List.generate(cantidad - primera, (i) => primera + i),
    ];
  }

  final indices = List.generate(cantidad, (i) => i);
  return orientacion == Orientation.portrait
      ? indices.map((i) => [i]).toList()
      : [indices];
}
```

- [ ] **Step 4: Correr los tests para verificar que pasan**

Run: `flutter test test/panel_layout_test.dart`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/games/panel_layout.dart test/panel_layout_test.dart
git commit -m "feat(games): layout de paneles independiente del juego"
```

---

### Task 8: Widgets compartidos

Todavía no se conectan: se crean y quedan listos para Task 9. Los counters viejos siguen funcionando mientras tanto.

**Files:**
- Create: `lib/widgets/felt_background.dart`
- Create: `lib/widgets/wood_panel.dart`
- Create: `lib/widgets/game_header.dart`
- Create: `lib/widgets/name_dialog.dart`
- Create: `lib/widgets/score_panel.dart`
- Modify: `lib/widgets/winner_bottom_sheet.dart` (usar el tema en vez de `GoogleFonts` suelto)

**Interfaces:**
- Consumes: `MesaColors` (Task 1), `MatchstickCounter` (Tasks 3-4).
- Produces:
  - `FeltBackground({required Widget child})`
  - `WoodPanel({required Widget child, bool destacado = false, EdgeInsets margin})`
  - `GameHeader({required String titulo, required VoidCallback onReiniciar})`
  - `Future<String?> mostrarNameDialog(BuildContext context, {required String titulo, required String actual})`
  - `ScorePanel({required String nombre, required int puntaje, String? chip, bool chipActivo = false, required VoidCallback onSumar, required VoidCallback? onRestar, required VoidCallback onRenombrar})`

- [ ] **Step 1: Fondo de paño**

`lib/widgets/felt_background.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Mesa de paño: degradé radial más una trama diagonal muy sutil.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.3, -.5),
          radius: 1.2,
          colors: [
            MesaColors.panoLuz,
            MesaColors.panoBase,
            MesaColors.panoSombra,
          ],
          stops: [0, .6, 1],
        ),
      ),
      child: CustomPaint(
        painter: _TramaPano(),
        child: child,
      ),
    );
  }
}

class _TramaPano extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final clara = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    final oscura = Paint()
      ..color = Colors.black.withValues(alpha: .05)
      ..strokeWidth = 1;

    const paso = 6.0;
    for (var x = -size.height; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), clara);
      canvas.drawLine(
          Offset(x + paso / 2, 0), Offset(x + paso / 2 - size.height, size.height), oscura);
    }
  }

  @override
  bool shouldRepaint(covariant _TramaPano oldDelegate) => false;
}
```

- [ ] **Step 2: Panel de madera**

`lib/widgets/wood_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Tabla de madera sobre el paño. `destacado` la ilumina — lo usa el hito.
///
/// Al pasar a destacado da un pulso corto: es el "pasa a las buenas" que
/// antes vivía como ScaleTransition dentro del contador de Truco.
class WoodPanel extends StatefulWidget {
  final Widget child;
  final bool destacado;
  final EdgeInsets margin;

  const WoodPanel({
    super.key,
    required this.child,
    this.destacado = false,
    this.margin = const EdgeInsets.all(8),
  });

  @override
  State<WoodPanel> createState() => _WoodPanelState();
}

class _WoodPanelState extends State<WoodPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _escala = Tween<double>(begin: 1, end: 1.04)
      .animate(CurvedAnimation(parent: _pulso, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(WoodPanel anterior) {
    super.didUpdateWidget(anterior);
    if (widget.destacado && !anterior.destacado) {
      _pulso.forward().then((_) => _pulso.reverse());
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.destacado
                ? const [Color(0xFF8E5E34), MesaColors.maderaClara]
                : const [MesaColors.maderaClara, MesaColors.maderaOscura],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.destacado ? MesaColors.dorado : MesaColors.maderaBorde,
            width: widget.destacado ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x73000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 3: Header y diálogo de nombre**

`lib/widgets/game_header.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

class GameHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback onReiniciar;

  const GameHeader({
    super.key,
    required this.titulo,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.refresh, color: MesaColors.doradoClaro),
            onPressed: () => _confirmar(context),
          ),
        ],
      ),
    );
  }

  void _confirmar(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar partida?'),
        content: const Text('Se perderán los puntos actuales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onReiniciar();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}
```

`lib/widgets/name_dialog.dart`:

```dart
import 'package:flutter/material.dart';

/// Pide un nombre. Devuelve null si se cancela.
Future<String?> mostrarNameDialog(
  BuildContext context, {
  required String titulo,
  required String actual,
}) {
  final controller = TextEditingController(text: actual);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Ingresá el nombre',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Panel de puntaje**

`lib/widgets/score_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'matchstick_counter.dart';
import 'wood_panel.dart';

/// Un participante: nombre, chip opcional del hito, fósforos, puntaje y
/// botón de restar. Tocar el panel suma; mantener el nombre lo edita.
class ScorePanel extends StatelessWidget {
  final String nombre;
  final int puntaje;
  final String? chip;
  final bool chipActivo;
  final VoidCallback onSumar;
  final VoidCallback? onRestar;
  final VoidCallback onRenombrar;

  const ScorePanel({
    super.key,
    required this.nombre,
    required this.puntaje,
    this.chip,
    this.chipActivo = false,
    required this.onSumar,
    required this.onRestar,
    required this.onRenombrar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onSumar,
      child: WoodPanel(
        destacado: chipActivo,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onLongPress: onRenombrar,
                child: Text(
                  nombre,
                  style: textos.headlineMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (chip != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _Chip(texto: chip!, activo: chipActivo),
              ),
            Expanded(child: MatchstickCounter(points: puntaje)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton.tonal(
                    onPressed: onRestar,
                    style: FilledButton.styleFrom(
                      backgroundColor: MesaColors.brasa,
                      foregroundColor: MesaColors.crema,
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('−'),
                  ),
                  Text('$puntaje', style: textos.displaySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;

  const _Chip({required this.texto, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? MesaColors.dorado : Colors.black.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: MesaColors.dorado, width: 1),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              color: activo ? MesaColors.maderaBorde : MesaColors.doradoClaro,
            ),
      ),
    );
  }
}
```

- [ ] **Step 5: Pasar el bottom sheet al tema**

En `lib/widgets/winner_bottom_sheet.dart`, borrar el import de `google_fonts` y reemplazar los dos `style: GoogleFonts.raleway(...)` por estilos del tema:

```dart
          Text(
            '¡GANÓ $winnerName!',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
```

y

```dart
            label: const Text('Nueva Partida'),
```

Además, cambiar el `color: colorScheme.surface` del `Container` por `MesaColors.maderaOscura` con el import correspondiente.

- [ ] **Step 6: Verificar que analiza limpio y los tests siguen verdes**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `+3: All tests passed!`

Nota: los widgets nuevos todavía no se usan; el analyzer no se queja de eso porque son públicos.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets
git commit -m "feat(widgets): extrae paño, panel de madera, header, diálogo y panel de puntaje"
```

---

### Task 9: `CounterScreen`, catálogo, y borrar los counters viejos

El paso grande: Truco y Escoba dejan de ser pantallas y pasan a ser entradas de datos.

**Files:**
- Create: `lib/games/counter_screen.dart`
- Create: `lib/games/catalog.dart`
- Rewrite: `lib/main.dart`
- Delete: `lib/truco/truco_counter.dart`, `lib/escoba/escoba_counter.dart` (y sus carpetas)
- Test: `test/widget_test.dart` (existente, sin modificar)

**Interfaces:**
- Consumes: `GameSpec`, `Hito`, `ScoreGame`, `GameStorage`, `layoutFor` (Tasks 5-7); `FeltBackground`, `GameHeader`, `ScorePanel`, `mostrarNameDialog`, `WinnerBottomSheet` (Task 8); `mesaTheme` (Task 1).
- Produces: `CounterScreen({required GameSpec spec})` y `const List<GameSpec> catalogo`.

- [ ] **Step 1: El catálogo**

`lib/games/catalog.dart`:

```dart
import 'package:flutter/material.dart';

import 'game_spec.dart';

const truco = GameSpec(
  id: 'truco',
  titulo: 'Truco',
  icono: Icons.style,
  participantes: [2],
  topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(
    en: 15,
    soloSiTope: 30,
    antes: 'EN LAS MALAS',
    despues: 'EN LAS BUENAS',
  ),
);

const escoba = GameSpec(
  id: 'escoba',
  titulo: 'Escoba del 15',
  icono: Icons.grid_view,
  participantes: [2, 3, 4],
  topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
);

/// Agregar un contador nuevo es agregar una entrada acá. Por ejemplo, el
/// gallo (truco de a tres) sería otra const con `participantes: [3]`.
const catalogo = <GameSpec>[truco, escoba];
```

- [ ] **Step 2: La pantalla genérica**

`lib/games/counter_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import '../widgets/felt_background.dart';
import '../widgets/game_header.dart';
import '../widgets/name_dialog.dart';
import '../widgets/score_panel.dart';
import '../widgets/winner_bottom_sheet.dart';
import 'game_spec.dart';
import 'game_storage.dart';
import 'panel_layout.dart';
import 'score_game.dart';

/// Única pantalla de contador. Lo que cambia entre juegos es el GameSpec.
class CounterScreen extends StatefulWidget {
  final GameSpec spec;

  const CounterScreen({super.key, required this.spec});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final _storage = GameStorage();
  late ScoreGame _juego = ScoreGame.nueva(widget.spec);

  /// Tope elegido mientras se completa el setup, antes de empezar.
  int? _topeElegido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await _storage.migrar();
    final juego = await _storage.cargar(widget.spec);
    if (!mounted) return;
    setState(() => _juego = juego);
  }

  void _sumar(int indice, int puntos) {
    setState(() => _juego.sumar(indice, puntos));
    _storage.guardar(_juego);
    if (_juego.terminada) _mostrarGanador();
  }

  void _mostrarGanador() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => WinnerBottomSheet(
        winnerName: _juego.ganador ?? '',
        onReset: () {
          Navigator.pop(context);
          _volverAlSetup();
        },
      ),
    );
  }

  void _volverAlSetup() {
    setState(() {
      _juego.reiniciar();
      _juego.empezada = false;
      _topeElegido = null;
    });
    _storage.guardar(_juego);
  }

  Future<void> _renombrar(int indice) async {
    final nombre = await mostrarNameDialog(
      context,
      titulo: widget.spec.participantes.first > 2 || widget.spec.eligeParticipantes
          ? 'Nombre del jugador'
          : 'Nombre del equipo',
      actual: _juego.nombres[indice],
    );
    if (nombre == null) return;
    setState(() => _juego.renombrar(indice, nombre));
    _storage.guardar(_juego);
  }

  void _empezar({required int tope, required int participantes}) {
    setState(() => _juego.empezar(tope: tope, participantes: participantes));
    _storage.guardar(_juego);
  }

  @override
  Widget build(BuildContext context) {
    if (!_juego.empezada) return FeltBackground(child: _setup());

    return FeltBackground(
      child: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientacion) => Column(
            children: [
              GameHeader(
                titulo: _tituloPartida(),
                onReiniciar: _volverAlSetup,
              ),
              Expanded(child: _tablero(orientacion)),
            ],
          ),
        ),
      ),
    );
  }

  String _tituloPartida() =>
      widget.spec.eligeTope ? 'Partida a ${_juego.tope}' : widget.spec.titulo;

  Widget _tablero(Orientation orientacion) {
    final filas = layoutFor(_juego.participantes, orientacion);
    return Column(
      children: filas
          .map((fila) => Expanded(
                child: Row(
                  children: fila
                      .map((i) => Expanded(child: _panel(i)))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _panel(int indice) {
    final hito = widget.spec.hito;
    final muestra = _juego.muestraHito && hito != null;
    final cruzo = _juego.cruzoElHito(indice);

    return ScorePanel(
      nombre: _juego.nombres[indice],
      puntaje: _juego.puntajes[indice],
      chip: muestra ? (cruzo ? hito.despues : hito.antes) : null,
      chipActivo: cruzo,
      onSumar: () => _sumar(indice, 1),
      onRestar: _juego.terminada ? null : () => _sumar(indice, -1),
      onRenombrar: () => _renombrar(indice),
    );
  }

  // ---- setup ----

  Widget _setup() {
    // Primero el tope, después los participantes. Ese orden importa: es el
    // que dejan fijo los tests de widget.
    if (widget.spec.eligeTope && _topeElegido == null) {
      return _elegir(
        titulo: null,
        opciones: widget.spec.topes,
        etiqueta: widget.spec.etiquetaTope,
        alElegir: (tope) {
          if (widget.spec.eligeParticipantes) {
            setState(() => _topeElegido = tope);
          } else {
            _empezar(tope: tope, participantes: widget.spec.participantes.first);
          }
        },
      );
    }

    if (widget.spec.eligeParticipantes) {
      return _elegir(
        titulo: '¿Cuántos jugadores?',
        opciones: widget.spec.participantes,
        etiqueta: (n) => '$n jugadores',
        alElegir: (n) => _empezar(
          tope: _topeElegido ?? widget.spec.topes.first,
          participantes: n,
        ),
      );
    }

    // Nada que preguntar.
    return _elegir(
      titulo: null,
      opciones: const [0],
      etiqueta: (_) => 'Empezar',
      alElegir: (_) => _empezar(
        tope: widget.spec.topes.first,
        participantes: widget.spec.participantes.first,
      ),
    );
  }

  Widget _elegir({
    required String? titulo,
    required List<int> opciones,
    required String Function(int) etiqueta,
    required void Function(int) alElegir,
  }) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (titulo != null) ...[
              Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 28),
            ],
            ...opciones.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: FilledButton.tonal(
                  onPressed: () => alElegir(o),
                  style: FilledButton.styleFrom(
                    backgroundColor: MesaColors.maderaClara,
                    foregroundColor: MesaColors.crema,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 64, vertical: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: MesaColors.dorado),
                    ),
                  ),
                  child: Text(
                    etiqueta(o),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Reescribir `main.dart`**

`lib/main.dart` completo:

```dart
import 'package:flutter/material.dart';

import 'games/catalog.dart';
import 'games/counter_screen.dart';
import 'theme/mesa_theme.dart';

void main() {
  runApp(const ContadorDeTrucoApp());
}

class ContadorDeTrucoApp extends StatelessWidget {
  const ContadorDeTrucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador de Truco',
      theme: mesaTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _seleccionado = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seleccionado,
        children: [
          for (final spec in catalogo) CounterScreen(spec: spec),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seleccionado,
        onDestinationSelected: (i) => setState(() => _seleccionado = i),
        destinations: [
          for (final spec in catalogo)
            NavigationDestination(icon: Icon(spec.icono), label: spec.titulo),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Borrar los counters viejos**

```bash
git rm -r lib/truco lib/escoba
```

- [ ] **Step 5: Verificar que analiza limpio y que los 3 tests originales pasan**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `+30: All tests passed!` (3 de `widget_test` + 6 de `matchstick_layout_test` + 10 de `score_game_test` + 6 de `game_storage_test` + 5 de `panel_layout_test`).

Si falla `Truco tab shows game mode selection`, revisar que `etiquetasTope` tenga exactamente `A MALAS` y `A BUENAS`. Si falla `Escoba tab shows player count selection`, revisar que el título sea exactamente `¿Cuántos jugadores?` y las etiquetas `$n jugadores`.

- [ ] **Step 6: Commit**

```bash
git add -A lib test
git commit -m "refactor(games): Truco y Escoba pasan a ser entradas del catálogo"
```

---

### Task 10: Repaso visual en celular y tablet

Sin código nuevo. Es el chequeo que el spec pide antes de dar el rediseño por cerrado.

**Files:**
- Modify: los que haga falta ajustar según lo que se vea.

- [ ] **Step 1: Levantar la app**

Run: `flutter run -d web-server --web-port=8080`
Abrir `http://localhost:8080` en Firefox.

- [ ] **Step 2: Recorrer la checklist a ancho de celular (~400px)**

- Truco: elegir A BUENAS, sumar hasta pasar 15 en un equipo. El chip cambia a `EN LAS BUENAS` y el panel se ilumina.
- Los fósforos no se recortan en ningún puntaje entre 1 y 30.
- Restar nunca baja de 0.
- Mantener presionado un nombre lo edita; el nombre nuevo sobrevive a cambiar de pestaña y volver.
- Escoba con 4 jugadores: grilla 2x2, los cuatro paneles legibles.

- [ ] **Step 3: Repetir a ancho de tablet (~1100px)**

- Los fósforos aparecen en **más columnas**, no más gordos.
- Los paneles no quedan con huecos enormes ni el texto perdido en el medio.

- [ ] **Step 4: Rotar**

Achicar el alto de la ventana para simular horizontal. Truco pone los dos paneles lado a lado; Escoba con 4 mantiene la grilla 2x2.

- [ ] **Step 5: Ajustar lo que haga falta y commitear**

Si algo se ve mal, los puntos de ajuste probables son las constantes `minGrupo`/`maxGrupo` de `calcularLayout` (Task 2) y los tamaños de fuente del `textTheme` (Task 1).

```bash
git add -A
git commit -m "fix(ui): ajustes del repaso visual en celular y tablet"
```

- [ ] **Step 6: Actualizar la documentación**

En `README.md`, reemplazar la sección `## 📂 Estructura` por la estructura nueva (`lib/theme/`, `lib/games/`, `lib/widgets/`; ya no existen `lib/truco/` ni `lib/escoba/`), y en `## 🛠️ Pendientes conocidos` borrar el punto de **Layout de los fósforos** y el de **Duplicación**, que este trabajo resuelve.

En `CLAUDE.md`, actualizar la sección **Arquitectura**: el patrón ya no es "un juego = un archivo autocontenido" sino "un juego = una entrada de `catalog.dart`", y las claves de persistencia ahora son `<id>_score_$i` con migración en `GameStorage`.

```bash
git add README.md CLAUDE.md
git commit -m "docs: actualiza estructura y pendientes tras el rediseño"
```

---

## Notas de ejecución

**Orden de dependencias:** 1 → 2 → 3 → 4 y 5 → 6, 7 pueden hacerse en cualquier orden entre sí. 8 necesita 1 y 4. 9 necesita todo. 10 va al final.

**Si un test de `widget_test.dart` se pone rojo**, la causa casi siempre es un texto cambiado. Están listados en Global Constraints; no se tocan.

**Verificación visual sin Android SDK:** `flutter run -d web-server --web-port=8080` y Firefox. No hay Chrome instalado y falta `cmake` para el target Linux, así que web es el camino. Redimensionar la ventana es la prueba de tablet.

**Antes de dar el trabajo por terminado**, probarlo en un dispositivo Android real. Eso requiere instalar el Android SDK, que está fuera del alcance de este plan.
