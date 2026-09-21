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
          expect(l.tamanoGrupo, inInclusiveRange(20, 96),
              reason: 'ancho=$ancho alto=$alto puntos=$puntos');
          expect(l.columnas, greaterThanOrEqualTo(1));

          final altoOcupado = l.filas * l.tamanoGrupo + (l.filas - 1) * 8;
          expect(altoOcupado, lessThanOrEqualTo(alto),
              reason:
                  'los fósforos no deben pintar fuera del panel: ancho=$ancho alto=$alto puntos=$puntos');
        }
      }
    }
  });

  test('siempre alcanzan las celdas para todos los grupos', () {
    final l = calcularLayout(puntos: 23, espacio: const Size(200, 300));
    expect(l.columnas * l.filas, greaterThanOrEqualTo(5)); // 23 puntos = 5 grupos
  });

  test('no elige un grupo más ancho que el espacio disponible', () {
    final l = calcularLayout(puntos: 1, espacio: const Size(80, 400));
    final ancho = l.columnas * l.tamanoGrupo + (l.columnas - 1) * 8;
    expect(ancho, lessThanOrEqualTo(80));
    expect(l.tamanoGrupo, lessThanOrEqualTo(80));
  });

  test('el ancho ocupado nunca excede el espacio, salvo el caso degradado', () {
    for (final ancho in [80.0, 150.0, 320.0, 600.0, 1024.0]) {
      for (final alto in [60.0, 120.0, 220.0, 400.0, 768.0]) {
        for (final puntos in [1, 5, 8, 15, 23, 30]) {
          final l = calcularLayout(puntos: puntos, espacio: Size(ancho, alto));
          final ocupado = l.columnas * l.tamanoGrupo + (l.columnas - 1) * 8;
          // El único caso permitido de desborde es el degradado: una sola
          // columna al tamaño mínimo en un espacio más angosto que eso.
          final degradado = l.columnas == 1 && l.tamanoGrupo == 44;
          if (!degradado) {
            expect(ocupado, lessThanOrEqualTo(ancho),
                reason: 'ancho=$ancho alto=$alto puntos=$puntos');
          }
        }
      }
    }
  });

  test('con gruposPorColumna fijo respeta esa cantidad de filas', () {
    // 30 puntos = 6 grupos; con 3 por columna tienen que ser 2 columnas.
    final l = calcularLayout(
      puntos: 30,
      espacio: const Size(340, 400),
      gruposPorColumna: 3,
    );
    expect(l.filas, 3);
    expect(l.columnas, 2);
    final ancho = l.columnas * l.tamanoGrupo + (l.columnas - 1) * l.separacion;
    expect(ancho, lessThanOrEqualTo(340));
  });

  test('una columna llena son 15 puntos en Truco', () {
    // 15 puntos = 3 grupos = exactamente una columna.
    final l = calcularLayout(
      puntos: 15,
      espacio: const Size(340, 400),
      gruposPorColumna: 3,
    );
    expect(l.filas, 3);
    expect(l.columnas, 1);
  });

  test('gruposPorColumna achica el grupo en vez de desbordar a lo ancho', () {
    // Panel angosto: tres por columna igual, pero más chicos.
    final l = calcularLayout(
      puntos: 15,
      espacio: const Size(180, 400),
      gruposPorColumna: 3,
    );
    expect(l.filas, 3);
    final ancho = l.columnas * l.tamanoGrupo + (l.columnas - 1) * l.separacion;
    expect(ancho, lessThanOrEqualTo(180));
  });

  test('escoba en panel alto y angosto: los tres grupos van en una columna', () {
    // Panel de la grilla 2x2 en un teléfono, ya descontados el botón − y el
    // puntaje. Antes caía al caso degradado y pintaba grupos de 20.
    final l = calcularLayout(puntos: 15, espacio: const Size(108, 200));
    expect(l.columnas, 1);
    expect(l.filas, 3);
    expect(l.tamanoGrupo, greaterThanOrEqualTo(44));
  });

  test('escoba en panel ancho y bajo: los tres grupos van en una fila', () {
    final l = calcularLayout(puntos: 15, espacio: const Size(300, 70));
    expect(l.filas, 1);
    expect(l.columnas, 3);
  });

  test('sin gruposPorColumna nunca mezcla filas y columnas si el eje único entra',
      () {
    for (final ancho in [110.0, 150.0, 320.0, 600.0, 1024.0]) {
      for (final alto in [120.0, 220.0, 400.0, 768.0]) {
        for (final puntos in [1, 5, 8, 15]) {
          final l = calcularLayout(puntos: puntos, espacio: Size(ancho, alto));
          expect(l.columnas == 1 || l.filas == 1, isTrue,
              reason:
                  'ancho=$ancho alto=$alto puntos=$puntos dio ${l.columnas}x${l.filas}');
        }
      }
    }
  });

  test('el eje único elige el que deja el grupo más grande', () {
    // 15 puntos = 3 grupos. Alto de sobra, ancho justo: gana la columna.
    final enColumna = calcularLayout(puntos: 15, espacio: const Size(100, 400));
    // Mismo espacio al revés: gana la fila, con el mismo tamaño.
    final enFila = calcularLayout(puntos: 15, espacio: const Size(400, 100));
    expect(enColumna.columnas, 1);
    expect(enFila.filas, 1);
    expect(enColumna.tamanoGrupo, enFila.tamanoGrupo);
  });
}
