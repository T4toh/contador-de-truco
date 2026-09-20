import 'package:flutter/widgets.dart';

/// Un juego contador descrito como dato.
///
/// Una lista de un solo elemento significa "fijo, no se pregunta". Con más
/// de uno, el setup lo pregunta. Esa es toda la regla.
class GameSpec {
  /// Prefijo de las claves de persistencia y clave del catálogo.
  final String id;
  final String titulo;
  final IconData icono;
  final List<int> participantes;
  final List<int> topes;

  /// Cómo se presenta cada tope en el setup. Si es null, "$tope puntos".
  final Map<int, String>? etiquetasTope;

  /// Debe tener al menos `participantes.last` elementos: al empezar una
  /// partida se toman los primeros N.
  final List<String> nombresPorDefecto;

  final Hito? hito;

  const GameSpec({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.participantes,
    required this.topes,
    this.etiquetasTope,
    required this.nombresPorDefecto,
    this.hito,
  });

  bool get eligeTope => topes.length > 1;
  bool get eligeParticipantes => participantes.length > 1;

  String etiquetaTope(int tope) => etiquetasTope?[tope] ?? '$tope puntos';
}

/// El "pasa a las buenas": un umbral intermedio que cambia el aspecto del
/// panel sin terminar la partida.
class Hito {
  final int en;

  /// Si no es null, el hito solo aplica cuando el tope elegido es este.
  final int? soloSiTope;

  final String antes;
  final String despues;

  const Hito({
    required this.en,
    this.soloSiTope,
    required this.antes,
    required this.despues,
  });
}
