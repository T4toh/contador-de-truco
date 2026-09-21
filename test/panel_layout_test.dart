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

  test('cuatro jugadores: grilla 2x2 cuando hay alto para dos filas', () {
    const grilla = [
      [0, 1],
      [2, 3],
    ];
    expect(layoutFor(4, Orientation.portrait), grilla);
    expect(layoutFor(4, Orientation.landscape), grilla);
    expect(layoutFor(4, Orientation.landscape, altoDisponible: 600), grilla);
  });

  test('cuatro jugadores en un tablero bajo: una sola fila', () {
    // Landscape de teléfono: dos filas dejan paneles tan bajos que el
    // puntaje, los fósforos y el botón − quedan clipeados.
    expect(layoutFor(4, Orientation.landscape, altoDisponible: 180), [
      [0, 1, 2, 3],
    ]);
    expect(layoutFor(4, Orientation.portrait, altoDisponible: 180), [
      [0, 1, 2, 3],
    ]);
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
        for (final alto in [null, 180.0, 600.0]) {
          final planos = layoutFor(cantidad, o, altoDisponible: alto)
              .expand((f) => f)
              .toList()
            ..sort();
          expect(planos, List.generate(cantidad, (i) => i),
              reason: 'cantidad=$cantidad orientacion=$o alto=$alto');
        }
      }
    }
  });
}
