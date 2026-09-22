import 'dart:convert';
import 'dart:math' as math;

import 'reglas.dart';

const minJugadores = 2;
const maxJugadores = 6;

const nombresPorDefecto = [
  'Jugador 1',
  'Jugador 2',
  'Jugador 3',
  'Jugador 4',
  'Jugador 5',
  'Jugador 6',
];

/// Para columnas angostas, mientras el nombre siga siendo el de fábrica.
const nombresCortos = ['J#1', 'J#2', 'J#3', 'J#4', 'J#5', 'J#6'];

/// Estado y reglas de una partida de Generala. Sin widgets: se testea directo.
///
/// Lo posee el State de GeneralaScreen, que envuelve las mutaciones en
/// setState y guarda después de cada una.
class GeneralaGame {
  List<String> nombres;

  /// `planilla[jugador][casilla.index]`: null vacía, 0 tachada.
  List<List<int?>> planilla;
  bool empezada;
  bool terminada;

  /// Índices de los ganadores. Vacía si no terminó; varios si hay empate.
  List<int> ganadores;

  GeneralaGame({
    required this.nombres,
    required this.planilla,
    this.empezada = false,
    this.terminada = false,
    this.ganadores = const [],
  });

  factory GeneralaGame.nueva() => GeneralaGame(
    nombres: nombresPorDefecto.take(minJugadores).toList(),
    planilla: _vacia(minJugadores),
  );

  static List<List<int?>> _vacia(int jugadores) => List.generate(
    jugadores,
    (_) => List<int?>.filled(Casilla.values.length, null),
  );

  int get participantes => planilla.length;

  void empezar(int participantes) {
    final n = participantes.clamp(minJugadores, maxJugadores);
    // Los nombres que el usuario haya puesto sobreviven a una partida nueva.
    nombres = List.generate(
      n,
      (i) => i < nombres.length ? nombres[i] : nombresPorDefecto[i],
    );
    planilla = _vacia(n);
    empezada = true;
    terminada = false;
    ganadores = [];
  }

  int? valor(int jugador, Casilla casilla) => planilla[jugador][casilla.index];

  void anotar(int jugador, Casilla casilla, Jugada jugada) {
    if (terminada) return;
    planilla[jugador][casilla.index] = jugada.valor;
    if (jugada.ganaPartida) {
      terminada = true;
      ganadores = [jugador];
      return;
    }
    if (completa) {
      terminada = true;
      ganadores = _conTotalMaximo();
    }
  }

  void borrar(int jugador, Casilla casilla) {
    if (terminada) return;
    planilla[jugador][casilla.index] = null;
  }

  int total(int jugador) =>
      planilla[jugador].whereType<int>().fold(0, (a, b) => a + b);

  int cargadas(int jugador) => planilla[jugador].whereType<int>().length;

  bool get completa => planilla.every((fila) => fila.every((v) => v != null));

  /// 1 a `Casilla.values.length`: la casilla que están completando. Manda el
  /// que menos cargó.
  int get vuelta {
    final minimo = planilla
        .map((f) => f.whereType<int>().length)
        .reduce(math.min);
    return (minimo + 1).clamp(1, Casilla.values.length);
  }

  List<int> _conTotalMaximo() {
    final totales = List.generate(participantes, total);
    final maximo = totales.reduce(math.max);
    return [
      for (var i = 0; i < participantes; i++)
        if (totales[i] == maximo) i,
    ];
  }

  void renombrar(int jugador, String nombre) {
    if (nombre.isEmpty) return;
    nombres[jugador] = nombre;
  }

  /// Vuelve al setup conservando los nombres.
  void reiniciar() {
    planilla = _vacia(participantes);
    empezada = false;
    terminada = false;
    ganadores = [];
  }

  Map<String, dynamic> toJson() => {
    'nombres': nombres,
    'planilla': planilla,
    'empezada': empezada,
    'terminada': terminada,
    'ganadores': ganadores,
  };

  /// null si el texto no es una partida válida: el que llama arranca una nueva.
  static GeneralaGame? desdeJson(String? texto) {
    if (texto == null) return null;
    try {
      final m = jsonDecode(texto) as Map<String, dynamic>;
      final planilla = [
        for (final fila in m['planilla'] as List)
          [for (final v in fila as List) v as int?],
      ];
      final n = planilla.length;
      if (n < minJugadores || n > maxJugadores) return null;
      if (planilla.any((f) => f.length != Casilla.values.length)) return null;
      final nombres = [for (final s in m['nombres'] as List) s as String];
      if (nombres.length != n) return null;
      final ganadores = [for (final g in m['ganadores'] as List) g as int];
      if (ganadores.any((g) => g < 0 || g >= n)) return null;
      return GeneralaGame(
        nombres: nombres,
        planilla: planilla,
        empezada: m['empezada'] as bool,
        terminada: m['terminada'] as bool,
        ganadores: ganadores,
      );
    } catch (_) {
      return null;
    }
  }
}
