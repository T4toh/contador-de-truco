import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/games/catalog.dart';
import 'package:contador_de_truco/games/counter_screen.dart';
import 'package:contador_de_truco/theme/mesa_theme.dart';
import 'package:contador_de_truco/widgets/matchstick_counter.dart';
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
      'truco_name_0': 'Nosotros',
      'truco_name_1': 'Ellos',
      'truco_score_0': 14,
      'truco_score_1': 0,
    });
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();
    expect(find.text('Nosotros'), findsOneWidget);

    // Renombrar de verdad: mantener presionado, escribir y guardar (Fix 1:
    // el diálogo ya no crashea porque el TextFormField maneja su propio
    // controller en vez de que name_dialog.dart lo disponga a destiempo).
    await tester.longPress(find.text('Nosotros'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre del equipo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Los Pibes');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Los Pibes'), findsOneWidget);

    // Un punto más termina la partida y muestra la planilla de ganador.
    await tester.tap(find.byType(ScorePanel).first);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Nueva Partida'), findsOneWidget);

    await tester.tap(find.text('Nueva Partida'));
    await tester.pumpAndSettle();

    // Partida nueva: el nombre renombrado debe seguir ahí (Fix 1).
    await tester.tap(find.text('A MALAS'));
    await tester.pump();

    expect(find.text('Los Pibes'), findsOneWidget);
  });

  testWidgets('el lápiz abre el diálogo de renombrar sin sumar puntos',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();
    await tester.tap(find.text('A MALAS'));
    await tester.pump();

    expect(find.text('0'), findsNWidgets(2));

    final lapiz = find.ancestor(
      of: find.byIcon(Icons.edit).first,
      matching: find.byType(SizedBox),
    ).first;
    final area = tester.getSize(lapiz);
    expect(area.width, greaterThanOrEqualTo(44));
    expect(area.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    expect(find.text('Nombre del equipo'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets(
      'un nombre muy largo se acorta y no tapa el chip del hito',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'truco_tope': 30,
      'truco_empezada': true,
      'truco_participantes': 2,
      'truco_name_0': 'Un Nombre De Equipo Larguísimo Que No Entra',
      'truco_name_1': 'Ellos',
      'truco_score_0': 0,
      'truco_score_1': 0,
    });
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();

    expect(find.text('EN LAS MALAS'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el panel del Truco agrupa los fósforos de a tres por columna',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();
    await tester.tap(find.text('A MALAS'));
    await tester.pump();

    final contador =
        tester.widget<MatchstickCounter>(find.byType(MatchstickCounter).first);
    expect(contador.gruposPorColumna, 3);
  });

  testWidgets(
      'a 30 puntos el Truco dibuja dos columnas de tres, no cuatro por línea',
      (tester) async {
    // 28 puntos = ceil(28/5) = 6 grupos, igual que a 30, pero sin quedar en
    // el tope (una partida en el tope ya está terminada y muestra la
    // planilla de ganador en vez del panel). Sembramos 28 directo por
    // SharedPreferences: llegar ahí a fuerza de taps sería mucho más lento
    // y no aporta nada a lo que el test verifica.
    SharedPreferences.setMockInitialValues({
      'truco_tope': 30,
      'truco_empezada': true,
      'truco_participantes': 2,
      'truco_name_0': 'Nosotros',
      'truco_name_1': 'Ellos',
      'truco_score_0': 28,
      'truco_score_1': 0,
    });
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: truco)),
    );
    await tester.pump();

    final pintores = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MatchstickGroupPainter,
    );
    // El panel de "Nosotros" (28 puntos = 6 grupos): los primeros 6
    // CustomPaint con ese painter son los suyos.
    final posiciones = tester
        .widgetList(pintores)
        .take(6)
        .map((w) => tester.getTopLeft(find.byWidget(w)))
        .toList();

    // Se redondea antes de agrupar para que diferencias de subpíxel no
    // inventen columnas o filas fantasma.
    final xs = posiciones.map((o) => o.dx.round()).toSet();
    final ys = posiciones.map((o) => o.dy.round()).toSet();

    expect(xs.length, 2, reason: 'dos columnas');
    expect(ys.length, 3, reason: 'tres filas por columna');

    // El puntaje se movió al costado del contador: sigue visible y
    // encontrable, no lo tapó el traslado.
    expect(find.text('28'), findsOneWidget);
  });

  /// Escoba a 4 con puntaje sembrado: 14 puntos son 3 grupos sin terminar
  /// la partida (el tope es 15 y ahí aparece la planilla de ganador).
  Map<String, Object> escobaA4({int puntos = 14}) => {
        'escoba_tope': 15,
        'escoba_empezada': true,
        'escoba_participantes': 4,
        'escoba_name_0': 'Jugador 1',
        'escoba_name_1': 'Jugador 2',
        'escoba_name_2': 'Jugador 3',
        'escoba_name_3': 'Jugador 4',
        'escoba_score_0': puntos,
        'escoba_score_1': 0,
        'escoba_score_2': 0,
        'escoba_score_3': 0,
      };

  testWidgets('la Escoba a 4 en un teléfono no desborda ni achica los fósforos',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(escobaA4());
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: escoba)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final pintores = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MatchstickGroupPainter,
    );
    final grupos = tester.widgetList(pintores).take(3).toList();
    final posiciones =
        grupos.map((w) => tester.getTopLeft(find.byWidget(w))).toList();

    // Un solo eje: los tres grupos comparten columna.
    expect(posiciones.map((o) => o.dx.round()).toSet().length, 1,
        reason: 'una sola columna');
    expect(posiciones.map((o) => o.dy.round()).toSet().length, 3,
        reason: 'tres filas');

    // Antes de arreglar el ancho del panel esto daba el mínimo de 20.
    final lado = tester.getSize(find.byWidget(grupos.first)).width;
    expect(lado, greaterThanOrEqualTo(44));
  });

  testWidgets('en un teléfono la Escoba muestra J#1; en tablet, Jugador 1',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final caso in [
      (const Size(390, 844), 'J#1', 'Jugador 1'),
      (const Size(1600, 1000), 'Jugador 1', 'J#1'),
    ]) {
      tester.view.physicalSize = caso.$1;
      SharedPreferences.setMockInitialValues(escobaA4());
      await tester.pumpWidget(
        MaterialApp(
          theme: mesaTheme(),
          home: CounterScreen(key: ValueKey(caso.$1), spec: escoba),
        ),
      );
      await tester.pump();

      expect(find.text(caso.$2), findsOneWidget, reason: '${caso.$1}');
      expect(find.text(caso.$3), findsNothing, reason: '${caso.$1}');
    }
  });

  testWidgets('un nombre puesto por el usuario no se abrevia nunca',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      ...escobaA4(),
      'escoba_name_0': 'Tato',
    });
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: escoba)),
    );
    await tester.pump();

    expect(find.text('Tato'), findsOneWidget);
    expect(find.text('J#1'), findsNothing);
  });

  testWidgets('la Escoba a 4 en un tablero bajo pasa a una fila y nada se clipea',
      (tester) async {
    // Landscape de teléfono con la NavigationBar y los insets del sistema
    // ya descontados: con la grilla 2x2, cada panel quedaba en ~78 px y el
    // puntaje, los fósforos y el botón − desaparecían.
    tester.view.physicalSize = const Size(986, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(escobaA4());
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: CounterScreen(spec: escoba)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final paneles = find.byType(ScorePanel);
    expect(paneles, findsNWidgets(4));

    // Una sola fila: los cuatro paneles arrancan al mismo alto.
    // Los cuatro Text('−') son idénticos, así que hay que ir por índice:
    // find.byWidget() no los distingue.
    final topes = <int>{};
    for (var i = 0; i < 4; i++) {
      topes.add(tester.getTopLeft(paneles.at(i)).dy.round());

      // El botón − sigue dibujándose dentro de la pantalla.
      final rect = tester.getRect(find.text('−').at(i));
      expect(rect.height, greaterThan(0), reason: 'botón $i');
      expect(rect.bottom, lessThanOrEqualTo(300), reason: 'botón $i');
    }
    expect(topes.length, 1, reason: 'los cuatro en la misma fila');

    // Y los fósforos del que tiene puntaje siguen dibujándose.
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MatchstickGroupPainter,
      ),
      findsWidgets,
    );
    expect(find.text('14'), findsOneWidget);
  });
}
