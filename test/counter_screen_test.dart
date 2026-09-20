import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/games/catalog.dart';
import 'package:contador_de_truco/games/counter_screen.dart';
import 'package:contador_de_truco/theme/mesa_theme.dart';
import 'package:contador_de_truco/widgets/score_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no hay overflow en landscape de celular (Truco y Escoba)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final spec in [truco, escoba]) {
      SharedPreferences.setMockInitialValues({});
      // Key distinto por spec: sin esto, Flutter reutiliza el State del
      // CounterScreen anterior (mismo tipo, mismo slot) en vez de arrancar
      // uno nuevo, y el segundo spec de la vuelta nunca se ve reflejado.
      await tester.pumpWidget(
        MaterialApp(
          theme: mesaTheme(),
          home: CounterScreen(key: ValueKey(spec.id), spec: spec),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '${spec.id}: setup');

      final etiqueta = spec.eligeTope
          ? spec.etiquetaTope(spec.topes.last)
          : '${spec.participantes.last} jugadores';
      await tester.tap(find.text(etiqueta));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: '${spec.id}: partida iniciada');
    }
  });

  testWidgets('tocar el panel suma, el botón − resta y no baja de cero',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();
    await tester.tap(find.text('A MALAS'));
    await tester.pump();

    final panel = find.byType(ScorePanel).first;
    final restar = find.text('−').first;

    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(panel);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(restar);
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(restar);
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('un nombre puesto por el usuario sobrevive a una partida nueva',
      (tester) async {
    // Simplificación: en vez de escribir el nombre a través del diálogo de
    // renombrar (mostrarNameDialog), se precarga en el storage un nombre
    // "puesto a mano" para el equipo 0, ya con la partida arrancada a un
    // punto del tope. Se probó primero la vía real (longPress → escribir →
    // Guardar) y dispara un bug de framework preexistente y ajeno a estos
    // fixes: `name_dialog.dart` dispone el TextEditingController en el
    // `.then()` apenas se resuelve el pop, mientras el AlertDialog todavía
    // está en su animación de salida; el siguiente pump reconstruye ese
    // TextField con el controller ya disposed ("A TextEditingController was
    // used after being disposed"), y de ahí en más el árbol de widgets queda
    // corrupto (llega a lanzar '_dependents.isEmpty': is not true). Pasa
    // igual con un solo pump() o con pumpAndSettle(), así que no hay forma
    // de expresar ese paso con lo que da flutter_test sin taparlo a mano.
    // Se reporta aparte; acá se prueba la regresión real de Fix 1 (que
    // `empezar` no pise nombres) sin pasar por ese camino roto.
    //
    // Viewport de teléfono normal (no el 800x600 por defecto de flutter
    // test): con el default, la planilla de ganador desborda y el botón
    // "Nueva Partida" queda fuera del área tocable.
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'truco_tope': 15,
      'truco_empezada': true,
      'truco_participantes': 2,
      'truco_name_0': 'Los Pibes',
      'truco_name_1': 'Ellos',
      'truco_score_0': 14,
      'truco_score_1': 0,
    });
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();
    expect(find.text('Los Pibes'), findsOneWidget);

    // Un punto más termina la partida y muestra la planilla de ganador.
    await tester.tap(find.byType(ScorePanel).first);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Nueva Partida'), findsOneWidget);

    await tester.tap(find.text('Nueva Partida'));
    await tester.pumpAndSettle();

    // Partida nueva: el nombre puesto a mano debe seguir ahí (Fix 1).
    await tester.tap(find.text('A MALAS'));
    await tester.pump();

    expect(find.text('Los Pibes'), findsOneWidget);
  });
}
