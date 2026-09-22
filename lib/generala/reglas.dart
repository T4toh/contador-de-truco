/// Puntaje de la Generala según el reglamento de Ruibal, el que viene en la
/// caja del juego:
/// https://ruibalgames.com/wp-content/uploads/2015/11/Reglamento-Generala.pdf
///
/// Once casillas, una por vuelta. Números: cantidad de dados × el número.
/// Escalera 20, full 30, póker 40; +5 si salen servidos (en el primer tiro).
/// Generala 60; generala servida gana la partida en el acto. Generala doble
/// 100 (segunda generala; servida también gana). No figura en el PDF del
/// reglamento pero sí en la planilla impresa de Ruibal.
enum Casilla {
  uno('Unos', '⚀', 1),
  dos('Doses', '⚁', 2),
  tres('Treses', '⚂', 3),
  cuatro('Cuatros', '⚃', 4),
  cinco('Cincos', '⚄', 5),
  seis('Seises', '⚅', 6),
  escalera('Escalera', 'E', null),
  full('Full', 'F', null),
  poker('Póker', 'P', null),
  generala('Generala', 'G', null),
  doble('Generala doble', 'G2', null);

  const Casilla(this.etiqueta, this.simbolo, this.numero);

  final String etiqueta;

  /// Lo que se imprime en la fila de la planilla, como en la de papel: caras
  /// de dado y una letra.
  final String simbolo;

  /// El número del dado en las seis casillas de números; null en los juegos
  /// mayores.
  final int? numero;

  /// Las jugadas válidas, siempre empezando por tachar. Es la única tabla de
  /// reglas de la app.
  List<Jugada> get opciones {
    final n = numero;
    if (n != null) {
      return [
        tachar,
        for (var cantidad = 1; cantidad <= 5; cantidad++)
          Jugada(n * cantidad, '${n * cantidad}'),
      ];
    }
    if (this == generala || this == doble) {
      final base = this == generala ? 60 : 100;
      return [
        tachar,
        Jugada(base, '$base'),
        Jugada(base, 'Servida, gana', servida: true, ganaPartida: true),
      ];
    }
    final base = switch (this) {
      escalera => 20,
      full => 30,
      poker => 40,
      _ => throw StateError('sin puntaje base: $name'),
    };
    return [
      tachar,
      Jugada(base, '$base'),
      Jugada(base + 5, '${base + 5} servida', servida: true),
    ];
  }

  /// La primera jugada con ese valor, o null si no es un valor válido acá.
  /// Sirve para saber cómo pintar una celda ya cargada.
  Jugada? jugadaPara(int valor) {
    for (final j in opciones) {
      if (j.valor == valor) return j;
    }
    return null;
  }
}

/// Una opción de la ficha: lo que se anota y cómo se muestra.
class Jugada {
  final int valor;
  final String etiqueta;
  final bool servida;

  /// Solo la generala servida: termina la partida con este jugador ganador.
  final bool ganaPartida;

  const Jugada(
    this.valor,
    this.etiqueta, {
    this.servida = false,
    this.ganaPartida = false,
  });
}

/// Tachar la casilla: vale cero y no se puede volver a anotar.
const tachar = Jugada(0, '✕');
