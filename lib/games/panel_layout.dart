import 'package:flutter/widgets.dart' show Orientation;

/// Cómo se acomodan los paneles de N participantes.
///
/// Devuelve filas de índices: `[[0,1],[2,3]]` es una grilla 2x2.
/// Reemplaza el layout que antes estaba hardcodeado en cada juego.
List<List<int>> layoutFor(int cantidad, Orientation orientacion) {
  // Cuatro van siempre en grilla, así cada uno tiene su esquina de la mesa.
  if (cantidad == 4) {
    return [
      [0, 1],
      [2, 3],
    ];
  }

  if (cantidad >= 5) {
    final primera = (cantidad / 2).ceil();
    return [
      List.generate(primera, (i) => i),
      List.generate(cantidad - primera, (i) => primera + i),
    ];
  }

  final indices = List.generate(cantidad, (i) => i);
  return orientacion == Orientation.portrait
      ? indices.map((i) => [i]).toList()
      : [indices];
}
