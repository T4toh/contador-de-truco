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
