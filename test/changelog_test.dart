import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/changelog/changelog.dart';
import 'package:contador_de_truco/changelog/novedades.dart';
import 'package:contador_de_truco/theme/mesa_theme.dart';
import 'package:contador_de_truco/update/update_checker.dart';
import 'package:contador_de_truco/widgets/setup_choice.dart';

const _md = '''
# Changelog

Texto de intro que no se muestra.

## [Sin publicar]

### Agregado
- **Generala**, tercer juego: planilla de 11 casillas
  para 2 a 6 jugadores.
- Ícono propio.

### Arreglado
- Rendimiento del paño.

## [1.0.2] - 2026-09-21

### Agregado
- La versión se muestra en el setup.

[Sin publicar]: https://github.com/T4toh/pulpero/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/T4toh/pulpero/compare/v1.0.1...v1.0.2
''';

void main() {
  group('parsearChangelog', () {
    test('una sección por versión, sin intro ni links de referencia', () {
      final secciones = parsearChangelog(_md);
      expect(secciones.map((s) => s.titulo), [
        'Sin publicar',
        '1.0.2 · 2026-09-21',
      ]);
    });

    test('subtítulos y viñetas en orden, con continuaciones unidas', () {
      final s = parsearChangelog(_md).first;
      expect(s.lineas, [
        const LineaChangelog.subtitulo('Agregado'),
        const LineaChangelog.vineta(
          'Generala, tercer juego: planilla de 11 casillas para 2 a 6 jugadores.',
        ),
        const LineaChangelog.vineta('Ícono propio.'),
        const LineaChangelog.subtitulo('Arreglado'),
        const LineaChangelog.vineta('Rendimiento del paño.'),
      ]);
    });

    test('saca la negrita de markdown', () {
      final s = parsearChangelog(
        '## [1.0.0] - 2026-01-01\n- **Truco** a 30.\n',
      );
      expect(
        s.single.lineas.single,
        const LineaChangelog.vineta('Truco a 30.'),
      );
    });

    test('texto vacío da lista vacía', () {
      expect(parsearChangelog(''), isEmpty);
    });
  });

  group('Novedades', () {
    test('instalación limpia: no muestra, pero recuerda la versión', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await Novedades().hayQueMostrar('1.1.0'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(Novedades.clave), '1.1.0');
    });

    test('upgrade desde una versión sin esta función: muestra', () async {
      // La 1.0.2 nunca guardó la versión vista, pero sí la fecha del último
      // chequeo de updates: eso distingue upgrade de instalación limpia.
      SharedPreferences.setMockInitialValues({
        UpdateChecker.claveUltimoChequeo: 123,
      });
      expect(await Novedades().hayQueMostrar('1.1.0'), isTrue);
      expect(await Novedades().hayQueMostrar('1.1.0'), isFalse);
    });

    test('misma versión que la última vista: no muestra', () async {
      SharedPreferences.setMockInitialValues({Novedades.clave: '1.1.0'});
      expect(await Novedades().hayQueMostrar('1.1.0'), isFalse);
    });

    test('versión distinta a la última vista: muestra una sola vez', () async {
      SharedPreferences.setMockInitialValues({Novedades.clave: '1.0.2'});
      expect(await Novedades().hayQueMostrar('1.1.0'), isTrue);
      expect(await Novedades().hayQueMostrar('1.1.0'), isFalse);
    });
  });

  testWidgets('tocar la versión en el setup abre el changelog empaquetado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: mesaTheme(),
        home: SetupChoice(
          opciones: const [0],
          etiqueta: (_) => 'Empezar',
          alElegir: (_) {},
          version: '1.0.2',
        ),
      ),
    );
    expect(find.text('Novedades'), findsNothing);

    await tester.tap(find.text('v1.0.2'));
    await tester.pumpAndSettle();

    expect(find.text('Novedades'), findsOneWidget);
    // El CHANGELOG.md real: se ve el título de la primera sección.
    final md = await rootBundle.loadString('CHANGELOG.md');
    expect(find.text(parsearChangelog(md).first.titulo), findsOneWidget);
  });
}
