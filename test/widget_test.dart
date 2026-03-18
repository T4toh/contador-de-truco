import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/main.dart';

void main() {
  testWidgets('HomeScreen renders tab navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ContadorDeTrucoApp());

    expect(find.text('Truco'), findsOneWidget);
    expect(find.text('Escoba del 15'), findsOneWidget);
  });

  testWidgets('Truco tab shows game mode selection', (WidgetTester tester) async {
    await tester.pumpWidget(const ContadorDeTrucoApp());

    expect(find.text('A MALAS'), findsOneWidget);
    expect(find.text('A BUENAS'), findsOneWidget);
  });

  testWidgets('Escoba tab shows player count selection', (WidgetTester tester) async {
    await tester.pumpWidget(const ContadorDeTrucoApp());

    await tester.tap(find.text('Escoba del 15'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cuántos jugadores?'), findsOneWidget);
    expect(find.text('2 jugadores'), findsOneWidget);
    expect(find.text('3 jugadores'), findsOneWidget);
    expect(find.text('4 jugadores'), findsOneWidget);
  });
}

