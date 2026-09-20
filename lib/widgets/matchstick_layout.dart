import 'dart:ui' show Size;

/// Resultado de acomodar los grupos de fósforos en el espacio disponible.
class MatchLayout {
  final double tamanoGrupo;
  final int columnas;
  final int filas;
  final double separacion;

  const MatchLayout({
    required this.tamanoGrupo,
    required this.columnas,
    required this.filas,
    required this.separacion,
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
    return MatchLayout(tamanoGrupo: minGrupo, columnas: 0, filas: 0, separacion: separacion);
  }

  for (var tamano = maxGrupo; tamano >= minGrupo; tamano -= paso) {
    final columnas = _columnasPara(tamano, espacio.width, separacion);
    if (columnas < 1) continue; // no entra ni una vez a lo ancho: probar más chico
    final filas = (grupos / columnas).ceil();
    final alto = filas * tamano + (filas - 1) * separacion;
    if (alto <= espacio.height) {
      return MatchLayout(tamanoGrupo: tamano, columnas: columnas, filas: filas, separacion: separacion);
    }
  }

  // Caso degradado: el espacio es demasiado bajo, o más angosto que minGrupo.
  // Se devuelve el mínimo con una columna, garantizando al menos un grupo
  // visible, aunque pueda desbordar a lo ancho en espacios muy angostos.
  final columnas = _columnasPara(minGrupo, espacio.width, separacion);
  final columnasFinales = columnas < 1 ? 1 : columnas;
  return MatchLayout(
    tamanoGrupo: minGrupo,
    columnas: columnasFinales,
    filas: (grupos / columnasFinales).ceil(),
    separacion: separacion,
  );
}

int _columnasPara(double tamano, double ancho, double separacion) {
  return ((ancho + separacion) / (tamano + separacion)).floor();
}
