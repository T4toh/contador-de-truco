import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/generala/generala_screen.dart';
import 'package:contador_de_truco/generala/planilla.dart';
import 'package:contador_de_truco/theme/mesa_theme.dart';

Future<void> _montar(WidgetTester tester, {int jugadores = 3}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(theme: mesaTheme(), home: const GeneralaScreen()),
  );
  await tester.pump();
  await tester.tap(find.text('$jugadores jugadores'));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el setup cita el reglamento y arma la planilla', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: const GeneralaScreen()),
    );
    await tester.pump();

    expect(find.text('¿Cuántos jugadores?'), findsOneWidget);
    expect(find.text('Puntaje según reglamento Ruibal'), findsOneWidget);
    for (var n = 2; n <= 8; n++) {
      expect(find.text('$n jugadores'), findsOneWidget);
    }

    await tester.tap(find.text('3 jugadores'));
    await tester.pump();
    expect(find.text('Vuelta 1 de 11'), findsOneWidget);
    expect(find.text('Jugador 1'), findsOneWidget);
    expect(find.text('Jugador 3'), findsOneWidget);
    expect(find.text('⚃'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una celda abre las fichas y anotar actualiza el total', (
    tester,
  ) async {
    await _montar(tester);

    await tester.tap(find.byKey(const ValueKey('celda-0-cuatro')));
    await tester.pumpAndSettle();
    expect(find.text('16'), findsOneWidget, reason: 'la ficha');
    expect(find.text('✕'), findsOneWidget, reason: 'tachar');

    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    expect(find.text('16'), findsNWidgets(2), reason: 'celda y total');
    expect(
      find.text('Vuelta 1 de 11'),
      findsOneWidget,
      reason: 'los otros dos no cargaron',
    );
  });

  testWidgets('una celda cargada ofrece borrar', (tester) async {
    await _montar(tester);
    await tester.tap(find.byKey(const ValueKey('celda-1-full')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('35 servida'));
    await tester.pumpAndSettle();
    expect(find.text('35'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('celda-1-full')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(find.text('35'), findsNothing);
  });

  testWidgets('mantener el nombre lo renombra', (tester) async {
    await _montar(tester);
    await tester.tap(find.text('Jugador 1'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre del jugador'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.edit), findsNWidgets(3));

    await tester.longPress(find.text('Jugador 2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Flor');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Flor'), findsOneWidget);
    expect(find.text('Jugador 2'), findsNothing);
  });

  testWidgets(
    'generala servida gana en el acto y nueva partida vuelve al setup',
    (tester) async {
      await _montar(tester, jugadores: 2);
      await tester.tap(find.byKey(const ValueKey('celda-1-generala')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Servida, gana'));
      await tester.pumpAndSettle();
      expect(find.text('¡GANÓ Jugador 2!'), findsOneWidget);

      await tester.tap(find.text('Nueva Partida'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cuántos jugadores?'), findsOneWidget);
    },
  );

  testWidgets('la partida sobrevive a remontar la pantalla', (tester) async {
    await _montar(tester);
    await tester.tap(find.byKey(const ValueKey('celda-2-poker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('40'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: const GeneralaScreen()),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('40'), findsNWidgets(2));
    expect(find.text('Jugador 3'), findsOneWidget);
  });

  testWidgets('8 jugadores en landscape de celular no desbordan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: const GeneralaScreen()),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('8 jugadores'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('8 jugadores'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // A 800x360 el ancho de columna (~83px) no baja del umbral angosto
    // (72px), así que la planilla no entra en modo angosto acá; lo que
    // importa en este viewport es que no desborde.
    expect(
      tester.getSize(find.byKey(const ValueKey('celda-0-uno'))).height,
      greaterThanOrEqualTo(34),
    );
    expect(
      find.descendant(
        of: find.byType(Planilla),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('8 jugadores en portrait usan nombres cortos', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: mesaTheme(), home: const GeneralaScreen()),
    );
    await tester.pump();
    await tester.tap(find.text('8 jugadores'));
    await tester.pump();
    expect(find.text('J#1'), findsOneWidget);
    expect(find.text('J#8'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });
}
