/// Puntaje de la Generala según el reglamento de Ruibal, el que viene en la
/// caja del juego:
/// https://ruibalgames.com/wp-content/uploads/2015/11/Reglamento-Generala.pdf
///
/// Diez casillas, una por vuelta. Números: cantidad de dados × el número.
/// Escalera 20, full 30, póker 40; +5 si salen servidos (en el primer tiro).
/// Generala 60; generala servida gana la partida en el acto. No hay doble
/// generala ni bonus de números: eso es de otras variantes (Yahtzee).
enum Casilla {
  uno('Unos', '1', 1),
  dos('Doses', '2', 2),
  tres('Treses', '3', 3),
  cuatro('Cuatros', '4', 4),
  cinco('Cincos', '5', 5),
  seis('Seises', '6', 6),
  escalera('Escalera', 'Esc', null),
  full('Full', 'Full', null),
  poker('Póker', 'Pók', null),
  generala('Generala', 'Gen', null);

  const Casilla(this.etiqueta, this.etiquetaCorta, this.numero);

  final String etiqueta;

  /// Para cuando la columna de etiquetas no tiene ancho para la larga.
  final String etiquetaCorta;

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
    if (this == generala) {
      return const [
        tachar,
        Jugada(60, '60'),
        Jugada(60, 'Servida, gana', servida: true, ganaPartida: true),
      ];
    }
    final base = switch (this) { escalera => 20, full => 30, _ => 40 };
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
