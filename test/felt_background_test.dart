import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/widgets/felt_background.dart';

void main() {
  testWidgets('el paño se pinta en su propia capa', (tester) async {
    // La trama son cientos de líneas con alpha: si comparte capa con el
    // contenido, se re-rasteriza en cada frame de cualquier animación y en
    // una tablet de gama baja tira el frame a ~40 ms. Medido en Redmi Pad SE.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: FeltBackground(child: SizedBox.expand()),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FeltBackground),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });
}
