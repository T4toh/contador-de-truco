// test/generala_game_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/generala/generala_game.dart';
import 'package:contador_de_truco/generala/generala_storage.dart';
import 'package:contador_de_truco/generala/reglas.dart';

void main() {
  test('nueva arranca sin empezar, con dos jugadores y planilla vacía', () {
    final g = GeneralaGame.nueva();
    expect(g.empezada, isFalse);
    expect(g.participantes, 2);
    expect(g.nombres, ['Jugador 1', 'Jugador 2']);
    expect(g.planilla.every((f) => f.length == 10 && f.every((v) => v == null)),
        isTrue);
  });

  test('empezar arma N jugadores y conserva nombres ya puestos', () {
    final g = GeneralaGame.nueva()..renombrar(0, 'Tato');
    g.empezar(4);
    expect(g.empezada, isTrue);
    expect(g.nombres, ['Tato', 'Jugador 2', 'Jugador 3', 'Jugador 4']);
    expect(g.planilla.length, 4);
  });

  test('empezar clampea a 2..6', () {
    expect((GeneralaGame.nueva()..empezar(1)).participantes, 2);
    expect((GeneralaGame.nueva()..empezar(9)).participantes, 6);
  });

  test('anotar escribe el valor y total suma los no nulos', () {
    final g = GeneralaGame.nueva()..empezar(2);
    g.anotar(0, Casilla.cuatro, Casilla.cuatro.opciones[4]); // 16
    g.anotar(0, Casilla.full, Casilla.full.opciones[2]); // 35 servido
    g.anotar(0, Casilla.uno, tachar);
    expect(g.valor(0, Casilla.cuatro), 16);
    expect(g.valor(0, Casilla.uno), 0);
    expect(g.valor(0, Casilla.dos), isNull);
    expect(g.total(0), 51);
    expect(g.total(1), 0);
    expect(g.cargadas(0), 3);
  });

  test('borrar vuelve la celda a vacía', () {
    final g = GeneralaGame.nueva()..empezar(2);
    g.anotar(1, Casilla.poker, Casilla.poker.opciones[1]);
    g.borrar(1, Casilla.poker);
    expect(g.valor(1, Casilla.poker), isNull);
    expect(g.total(1), 0);
  });

  test('vuelta es el mínimo de casillas cargadas más uno, hasta 10', () {
    final g = GeneralaGame.nueva()..empezar(2);
    expect(g.vuelta, 1);
    g.anotar(0, Casilla.uno, tachar);
    expect(g.vuelta, 1, reason: 'el otro todavía no cargó nada');
    g.anotar(1, Casilla.uno, tachar);
    expect(g.vuelta, 2);
  });

  test('completar la planilla termina y gana el mayor total', () {
    final g = GeneralaGame.nueva()..empezar(2);
    for (final c in Casilla.values) {
      g.anotar(0, c, tachar);
      g.anotar(1, c, c == Casilla.escalera ? c.opciones[1] : tachar);
    }
    expect(g.completa, isTrue);
    expect(g.terminada, isTrue);
    expect(g.ganadores, [1]);
    expect(g.vuelta, 10);
  });

  test('empate en el total devuelve varios ganadores', () {
    final g = GeneralaGame.nueva()..empezar(3);
    for (final c in Casilla.values) {
      for (var j = 0; j < 3; j++) {
        g.anotar(j, c, j == 2 ? tachar : c.opciones[1]);
      }
    }
    expect(g.terminada, isTrue);
    expect(g.ganadores, [0, 1]);
  });

  test('generala servida termina en el acto con ese ganador', () {
    final g = GeneralaGame.nueva()..empezar(3);
    g.anotar(0, Casilla.seis, Casilla.seis.opciones[5]); // 30
    g.anotar(1, Casilla.generala, Casilla.generala.opciones.last);
    expect(g.terminada, isTrue);
    expect(g.ganadores, [1]);
    expect(g.completa, isFalse);
    expect(g.valor(1, Casilla.generala), 60);
  });

  test('terminada ignora anotar y borrar', () {
    final g = GeneralaGame.nueva()..empezar(2);
    g.anotar(0, Casilla.cinco, Casilla.cinco.opciones[1]);
    g.anotar(1, Casilla.generala, Casilla.generala.opciones.last);
    g.anotar(0, Casilla.uno, Casilla.uno.opciones[5]);
    g.borrar(0, Casilla.cinco);
    expect(g.valor(0, Casilla.uno), isNull);
    expect(g.valor(0, Casilla.cinco), 5);
  });

  test('reiniciar vacía la planilla, conserva nombres y vuelve al setup', () {
    final g = GeneralaGame.nueva()..empezar(2);
    g.renombrar(1, 'Flor');
    g.anotar(1, Casilla.generala, Casilla.generala.opciones.last);
    g.reiniciar();
    expect(g.empezada, isFalse);
    expect(g.terminada, isFalse);
    expect(g.ganadores, isEmpty);
    expect(g.nombres, ['Jugador 1', 'Flor']);
    expect(g.total(1), 0);
  });

  test('renombrar ignora el vacío', () {
    final g = GeneralaGame.nueva()..renombrar(0, '');
    expect(g.nombres[0], 'Jugador 1');
  });

  test('JSON ida y vuelta preserva todo', () {
    final g = GeneralaGame.nueva()..empezar(3);
    g.renombrar(2, 'Flor');
    g.anotar(0, Casilla.tres, Casilla.tres.opciones[2]);
    g.anotar(2, Casilla.escalera, Casilla.escalera.opciones[2]);
    g.anotar(1, Casilla.uno, tachar);

    final copia = GeneralaGame.desdeJson(jsonEncode(g.toJson()))!;
    expect(copia.nombres, g.nombres);
    expect(copia.planilla, g.planilla);
    expect(copia.empezada, isTrue);
    expect(copia.terminada, isFalse);
    expect(copia.ganadores, isEmpty);
    expect(copia.total(2), 25);
  });

  test('desdeJson devuelve null con basura o formas inválidas', () {
    expect(GeneralaGame.desdeJson(null), isNull);
    expect(GeneralaGame.desdeJson('no es json'), isNull);
    expect(GeneralaGame.desdeJson('{"nombres":["a"],"planilla":[[1]]}'), isNull,
        reason: 'un jugador y una casilla');
    expect(
      GeneralaGame.desdeJson(jsonEncode({
        'nombres': ['a', 'b'],
        'planilla': [List.filled(10, null), List.filled(9, null)],
        'empezada': true,
        'terminada': false,
        'ganadores': [],
      })),
      isNull,
      reason: 'una fila corta',
    );
  });

  test('storage guarda y carga bajo generala_partida', () async {
    SharedPreferences.setMockInitialValues({});
    final g = GeneralaGame.nueva()..empezar(3);
    g.anotar(1, Casilla.full, Casilla.full.opciones[1]);
    await GeneralaStorage().guardar(g);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('generala_partida'), isNotNull);

    final cargado = await GeneralaStorage().cargar();
    expect(cargado.participantes, 3);
    expect(cargado.total(1), 30);
    expect(cargado.empezada, isTrue);
  });

  test('storage con basura guardada arranca una partida nueva', () async {
    SharedPreferences.setMockInitialValues({'generala_partida': '{rota'});
    final cargado = await GeneralaStorage().cargar();
    expect(cargado.empezada, isFalse);
    expect(cargado.participantes, 2);
  });
}
