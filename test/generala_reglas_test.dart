import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/generala/reglas.dart';

void main() {
  test('hay diez casillas, en el orden de la planilla', () {
    expect(Casilla.values.map((c) => c.etiqueta), [
      'Unos', 'Doses', 'Treses', 'Cuatros', 'Cincos', 'Seises',
      'Escalera', 'Full', 'Póker', 'Generala',
    ]);
  });

  test('toda casilla empieza por tachar', () {
    for (final c in Casilla.values) {
      expect(c.opciones.first, same(tachar), reason: c.name);
      expect(tachar.valor, 0);
      expect(tachar.etiqueta, '✕');
    }
  });

  test('los números valen cantidad por número, de 1 a 5 dados', () {
    expect(Casilla.cuatro.opciones.map((j) => j.valor), [0, 4, 8, 12, 16, 20]);
    expect(Casilla.seis.opciones.map((j) => j.etiqueta),
        ['✕', '6', '12', '18', '24', '30']);
    expect(Casilla.uno.opciones.any((j) => j.servida || j.ganaPartida), isFalse);
  });

  test('los juegos mayores valen 20/30/40 y +5 servidos', () {
    expect(Casilla.escalera.opciones.map((j) => j.valor), [0, 20, 25]);
    expect(Casilla.full.opciones.map((j) => j.valor), [0, 30, 35]);
    expect(Casilla.poker.opciones.map((j) => j.valor), [0, 40, 45]);
    expect(Casilla.poker.opciones.last.etiqueta, '45 servida');
    expect(Casilla.poker.opciones.last.servida, isTrue);
    expect(Casilla.poker.opciones[1].servida, isFalse);
  });

  test('la generala vale 60 y solo la servida gana la partida', () {
    final ops = Casilla.generala.opciones;
    expect(ops.map((j) => j.valor), [0, 60, 60]);
    expect(ops.last.etiqueta, 'Servida, gana');
    expect(ops.last.ganaPartida, isTrue);
    expect(ops.last.servida, isTrue);
    final conGana = Casilla.values.expand((c) => c.opciones).where((j) => j.ganaPartida);
    expect(conGana.length, 1);
  });

  test('jugadaPara identifica las servidas por su valor', () {
    expect(Casilla.escalera.jugadaPara(25)?.servida, isTrue);
    expect(Casilla.escalera.jugadaPara(20)?.servida, isFalse);
    expect(Casilla.generala.jugadaPara(60)?.servida, isFalse,
        reason: 'la primera coincidencia es la generala común');
    expect(Casilla.cuatro.jugadaPara(7), isNull);
  });

  test('etiquetas cortas para columnas angostas', () {
    expect(Casilla.cuatro.etiquetaCorta, '4');
    expect(Casilla.escalera.etiquetaCorta, 'Esc');
    expect(Casilla.poker.etiquetaCorta, 'Pók');
    expect(Casilla.generala.etiquetaCorta, 'Gen');
  });
}
