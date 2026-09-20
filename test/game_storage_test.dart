import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/games/game_spec.dart';
import 'package:contador_de_truco/games/game_storage.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migra una partida de Truco guardada con el esquema viejo', () async {
    SharedPreferences.setMockInitialValues({
      'truco_scoreA': 7,
      'truco_scoreB': 22,
      'truco_maxScore': 30,
      'truco_teamAName': 'Los Pibes',
      'truco_teamBName': 'Ellos',
      'truco_gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.puntajes, [7, 22]);
    expect(g.nombres, ['Los Pibes', 'Ellos']);
    expect(g.tope, 30);
    expect(g.empezada, isTrue);
  });

  test('migra una partida de Escoba guardada con el esquema viejo', () async {
    SharedPreferences.setMockInitialValues({
      'escoba_playerCount': 3,
      'escoba_gameStarted': true,
      'escoba_score_0': 4,
      'escoba_score_1': 11,
      'escoba_score_2': 0,
      'escoba_name_0': 'Tato',
      'escoba_name_1': 'Jugador 2',
      'escoba_name_2': 'Jugador 3',
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specEscoba);

    expect(g.puntajes, [4, 11, 0]);
    expect(g.nombres[0], 'Tato');
    expect(g.tope, 15);
    expect(g.empezada, isTrue);
  });

  test('migra el esquema legacy sin prefijo', () async {
    SharedPreferences.setMockInitialValues({
      'scoreA': 3,
      'scoreB': 9,
      'maxScore': 15,
      'teamAName': 'Nosotros',
      'teamBName': 'Los Otros',
      'gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.puntajes, [3, 9]);
    expect(g.nombres[1], 'Los Otros');
    expect(g.tope, 15);
  });

  test('sin nada guardado devuelve una partida nueva sin empezar', () async {
    SharedPreferences.setMockInitialValues({});

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.empezada, isFalse);
    expect(g.puntajes, [0, 0]);
    expect(g.nombres, ['Nosotros', 'Ellos']);
  });

  test('guardar y cargar da la vuelta completa', () async {
    SharedPreferences.setMockInitialValues({});

    final storage = GameStorage();
    final g = await storage.cargar(specEscoba);
    g.empezar(tope: 15, participantes: 4);
    g.renombrar(2, 'Colo');
    g.sumar(2, 6);
    await storage.guardar(g);

    final leido = await storage.cargar(specEscoba);
    expect(leido.puntajes, [0, 0, 6, 0]);
    expect(leido.nombres[2], 'Colo');
    expect(leido.empezada, isTrue);
  });

  test('la migración no corre dos veces', () async {
    SharedPreferences.setMockInitialValues({
      'truco_scoreA': 5,
      'truco_scoreB': 0,
      'truco_maxScore': 15,
      'truco_teamAName': 'Nosotros',
      'truco_teamBName': 'Ellos',
      'truco_gameStarted': true,
    });

    final storage = GameStorage();
    await storage.migrar();

    final g = await storage.cargar(specTruco);
    g.sumar(0, 3); // queda en 8
    await storage.guardar(g);

    await storage.migrar(); // no debe pisar con el valor viejo
    final otra = await storage.cargar(specTruco);
    expect(otra.puntajes[0], 8);
  });

  test('migra Truco v1 aunque falten claves companion', () async {
    SharedPreferences.setMockInitialValues({
      'truco_gameStarted': true,
      'truco_scoreA': 5,
      // faltan scoreB, maxScore, teamAName y teamBName
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specTruco);

    expect(g.puntajes, [5, 0]);
    expect(g.nombres, ['Nosotros', 'Ellos']);
    expect(g.tope, 30);
    expect(g.empezada, isTrue);
  });

  test('migra Escoba v1 aunque falte escoba_playerCount', () async {
    SharedPreferences.setMockInitialValues({
      'escoba_gameStarted': true,
      'escoba_score_0': 3,
      'escoba_name_0': 'Tato',
    });

    final storage = GameStorage();
    await storage.migrar();
    final g = await storage.cargar(specEscoba);

    expect(g.participantes, 2);
    expect(g.puntajes, [3, 0]);
    expect(g.nombres[0], 'Tato');
    expect(g.tope, 15);
  });

  test('cargar tolera un participantes persistido mayor que los nombres del spec',
      () async {
    SharedPreferences.setMockInitialValues({
      'escoba_participantes': 6, // de una versión con más jugadores
      'escoba_empezada': true,
      'escoba_tope': 15,
      'escoba_score_0': 4,
    });

    final storage = GameStorage();
    final g = await storage.cargar(specEscoba);

    expect(g.participantes, lessThanOrEqualTo(4));
    expect(g.puntajes.length, g.nombres.length);
    expect(g.puntajes[0], 4);
  });
}
