import 'game_spec.dart';

/// Estado y reglas de una partida. Sin widgets: se testea directo.
///
/// Lo posee el State de CounterScreen, que envuelve las mutaciones en
/// setState. No hay librería de state management.
class ScoreGame {
  final GameSpec spec;

  int tope;
  List<int> puntajes;
  List<String> nombres;
  bool empezada;
  bool terminada;
  String? ganador;

  ScoreGame({
    required this.spec,
    required this.tope,
    required this.puntajes,
    required this.nombres,
    this.empezada = false,
    this.terminada = false,
    this.ganador,
  });

  factory ScoreGame.nueva(GameSpec spec) {
    final cuantos = spec.participantes.first;
    return ScoreGame(
      spec: spec,
      tope: spec.topes.first,
      puntajes: List.filled(cuantos, 0),
      nombres: spec.nombresPorDefecto.take(cuantos).toList(),
    );
  }

  int get participantes => puntajes.length;

  void empezar({required int tope, required int participantes}) {
    this.tope = tope;
    puntajes = List.filled(participantes, 0);
    nombres = spec.nombresPorDefecto.take(participantes).toList();
    empezada = true;
    terminada = false;
    ganador = null;
  }

  void sumar(int indice, int puntos) {
    if (terminada) return;
    puntajes[indice] = (puntajes[indice] + puntos).clamp(0, tope);
    if (puntajes[indice] >= tope) {
      terminada = true;
      ganador = nombres[indice];
    }
  }

  void renombrar(int indice, String nombre) {
    if (nombre.isEmpty) return;
    nombres[indice] = nombre;
  }

  void reiniciar() {
    puntajes = List.filled(participantes, 0);
    terminada = false;
    ganador = null;
  }

  /// Si este juego muestra el chip del hito con el tope elegido.
  bool get muestraHito {
    final h = spec.hito;
    return h != null && (h.soloSiTope == null || h.soloSiTope == tope);
  }

  bool cruzoElHito(int indice) {
    final h = spec.hito;
    if (h == null || !muestraHito) return false;
    return puntajes[indice] >= h.en;
  }
}
