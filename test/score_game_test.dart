import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/games/game_spec.dart';
import 'package:contador_de_truco/games/score_game.dart';

const specTruco = GameSpec(
  id: 'truco',
  titulo: 'Truco',
  icono: Icons.style,
  participantes: [2],
  topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(
    en: 15,
    soloSiTope: 30,
    antes: 'EN LAS MALAS',
    despues: 'EN LAS BUENAS',
  ),
);

const specEscoba = GameSpec(
  id: 'escoba',
  titulo: 'Escoba del 15',
  icono: Icons.grid_view,
  participantes: [2, 3, 4],
  topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
);

void main() {
  test('empezar toma los primeros N nombres por defecto', () {
    final g = ScoreGame.nueva(specEscoba)..empezar(tope: 15, participantes: 3);
    expect(g.nombres, ['Jugador 1', 'Jugador 2', 'Jugador 3']);
    expect(g.puntajes, [0, 0, 0]);
    expect(g.empezada, isTrue);
  });

  test('restar de más no baja de cero', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 2);
    g.sumar(0, -5);
    expect(g.puntajes[0], 0);
  });

  test('sumar de más no pasa del tope', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 99);
    expect(g.puntajes[0], 15);
  });

  test('al llegar al tope termina y registra el ganador', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.renombrar(1, 'Los Pibes');
    g.sumar(1, 15);
    expect(g.terminada, isTrue);
    expect(g.ganador, 'Los Pibes');
  });

  test('terminada ignora sumas posteriores', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 15);
    g.sumar(1, 3);
    expect(g.puntajes[1], 0);
  });

  test('el hito se cruza a los 15 cuando el tope es 30', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 14);
    expect(g.cruzoElHito(0), isFalse);
    g.sumar(0, 1);
    expect(g.cruzoElHito(0), isTrue);
    expect(g.muestraHito, isTrue);
  });

  test('sin hito o con tope 15 el hito no se muestra', () {
    final truco15 = ScoreGame.nueva(specTruco)
      ..empezar(tope: 15, participantes: 2);
    expect(truco15.muestraHito, isFalse);

    final escoba = ScoreGame.nueva(specEscoba)
      ..empezar(tope: 15, participantes: 2);
    expect(escoba.muestraHito, isFalse);
    expect(escoba.cruzoElHito(0), isFalse);
  });

  test('reiniciar limpia puntajes pero conserva nombres', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, 'Los Pibes');
    g.sumar(0, 7);
    g.reiniciar();
    expect(g.puntajes, [0, 0]);
    expect(g.nombres[0], 'Los Pibes');
    expect(g.terminada, isFalse);
    expect(g.ganador, isNull);
  });

  test('renombrar con texto vacío no pisa el nombre', () {
    final g = ScoreGame.nueva(specTruco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, '');
    expect(g.nombres[0], 'Nosotros');
  });

  test('el spec sabe qué preguntar en el setup', () {
    expect(specTruco.eligeTope, isTrue);
    expect(specTruco.eligeParticipantes, isFalse);
    expect(specTruco.etiquetaTope(30), 'A BUENAS');
    expect(specEscoba.eligeTope, isFalse);
    expect(specEscoba.eligeParticipantes, isTrue);
    expect(specEscoba.etiquetaTope(15), '15 puntos');
  });
}
