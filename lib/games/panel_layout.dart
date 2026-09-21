import 'package:flutter/widgets.dart' show Orientation;

/// Alto mínimo que necesita un panel para que entren el nombre, los
/// fósforos y el botón de restar sin quedar clipeados.
const double altoMinimoPanel = 128;

/// Cómo se acomodan los paneles de N participantes.
///
/// Devuelve filas de índices: `[[0,1],[2,3]]` es una grilla 2x2.
/// Reemplaza el layout que antes estaba hardcodeado en cada juego.
///
/// `altoDisponible` es el alto del tablero. Si no se pasa, se asume que
/// sobra: es lo que hace más simples los tests que no miden nada.
List<List<int>> layoutFor(
  int cantidad,
  Orientation orientacion, {
  double? altoDisponible,
}) {
  if (cantidad == 4) {
    // En landscape de teléfono la grilla deja paneles de menos de 80 px:
    // el nombre se come el panel entero y el puntaje, los fósforos y el
    // botón − quedan clipeados. Con tan poco alto conviene una sola fila,
    // que le da a cada panel todo el alto del tablero.
    if (altoDisponible != null && altoDisponible < altoMinimoPanel * 2) {
      return [List.generate(4, (i) => i)];
    }
    // Con alto de sobra, grilla: así cada uno tiene su esquina de la mesa.
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
