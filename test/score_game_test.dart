import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/games/catalog.dart';
import 'package:contador_de_truco/games/score_game.dart';

void main() {
  test('empezar toma los primeros N nombres por defecto', () {
    final g = ScoreGame.nueva(escoba)..empezar(tope: 15, participantes: 3);
    expect(g.nombres, ['Jugador 1', 'Jugador 2', 'Jugador 3']);
    expect(g.puntajes, [0, 0, 0]);
    expect(g.empezada, isTrue);
  });

  test('restar de más no baja de cero', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 2);
    g.sumar(0, -5);
    expect(g.puntajes[0], 0);
  });

  test('sumar de más no pasa del tope', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 99);
    expect(g.puntajes[0], 15);
  });

  test('al llegar al tope termina y registra el ganador', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 15, participantes: 2);
    g.renombrar(1, 'Los Pibes');
    g.sumar(1, 15);
    expect(g.terminada, isTrue);
    expect(g.ganador, 'Los Pibes');
  });

  test('terminada ignora sumas posteriores', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 15, participantes: 2);
    g.sumar(0, 15);
    expect(g.terminada, isTrue);
    expect(g.puntajes[0], 15);
    g.sumar(1, 3);
    expect(g.puntajes[1], 0);
  });

  test('el hito se cruza a los 15 cuando el tope es 30', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 30, participantes: 2);
    g.sumar(0, 14);
    expect(g.cruzoElHito(0), isFalse);
    g.sumar(0, 1);
    expect(g.cruzoElHito(0), isTrue);
    expect(g.muestraHito, isTrue);
  });

  test('sin hito o con tope 15 el hito no se muestra', () {
    final truco15 = ScoreGame.nueva(truco)
      ..empezar(tope: 15, participantes: 2);
    expect(truco15.muestraHito, isFalse);

    final escobaJuego = ScoreGame.nueva(escoba)
      ..empezar(tope: 15, participantes: 2);
    expect(escobaJuego.muestraHito, isFalse);
    expect(escobaJuego.cruzoElHito(0), isFalse);
  });

  test('reiniciar limpia puntajes pero conserva nombres', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, 'Los Pibes');
    g.sumar(0, 7);
    g.reiniciar();
    expect(g.puntajes, [0, 0]);
    expect(g.nombres[0], 'Los Pibes');
    expect(g.terminada, isFalse);
    expect(g.ganador, isNull);
  });

  test('renombrar con texto vacío no pisa el nombre', () {
    final g = ScoreGame.nueva(truco)..empezar(tope: 30, participantes: 2);
    g.renombrar(0, '');
    expect(g.nombres[0], 'Nosotros');
  });

  test('el spec sabe qué preguntar en el setup', () {
    expect(truco.eligeTope, isTrue);
    expect(truco.eligeParticipantes, isFalse);
    expect(truco.etiquetaTope(30), 'A BUENAS');
    expect(escoba.eligeTope, isFalse);
    expect(escoba.eligeParticipantes, isTrue);
    expect(escoba.etiquetaTope(15), '15 puntos');
  });
}
