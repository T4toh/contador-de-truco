import 'dart:ui' show Size;

/// Resultado de acomodar los grupos de fósforos en el espacio disponible.
class MatchLayout {
  final double tamanoGrupo;
  final int columnas;
  final int filas;

  const MatchLayout({
    required this.tamanoGrupo,
    required this.columnas,
    required this.filas,
  });
}

/// Elige el tamaño de cada grupo de 5 fósforos y cómo se distribuyen.
///
/// A diferencia del `FittedBox` que reemplaza, acá el tamaño sale de medir
/// el espacio, no de estirar un dibujo hasta llenarlo. Por eso en tablet
/// aparecen más fósforos del mismo tamaño real en vez de fósforos gigantes.
MatchLayout calcularLayout({
  required int puntos,
  required Size espacio,
  double minGrupo = 44,
  double maxGrupo = 96,
  double separacion = 8,
  double paso = 4,
}) {
  final grupos = (puntos / 5).ceil();
  if (grupos <= 0) {
    return MatchLayout(tamanoGrupo: minGrupo, columnas: 0, filas: 0);
  }

  for (var tamano = maxGrupo; tamano >= minGrupo; tamano -= paso) {
    final columnas = _columnasPara(tamano, espacio.width, separacion);
    final filas = (grupos / columnas).ceil();
    final alto = filas * tamano + (filas - 1) * separacion;
    if (alto <= espacio.height) {
      return MatchLayout(tamanoGrupo: tamano, columnas: columnas, filas: filas);
    }
  }

  // Caso degradado: ni al mínimo entra a lo alto. Se devuelve el mínimo —
  // con tope 30 (6 grupos) esto no debería ocurrir en pantallas reales.
  final columnas = _columnasPara(minGrupo, espacio.width, separacion);
  return MatchLayout(
    tamanoGrupo: minGrupo,
    columnas: columnas,
    filas: (grupos / columnas).ceil(),
  );
}

int _columnasPara(double tamano, double ancho, double separacion) {
  final cabe = ((ancho + separacion) / (tamano + separacion)).floor();
  return cabe < 1 ? 1 : cabe;
}
