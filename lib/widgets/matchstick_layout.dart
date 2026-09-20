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
///
/// `minGrupo` es el tamaño mínimo preferido: por debajo de eso el dibujo
/// queda apretado. `pisoAbsoluto` es el mínimo real, sin excepción: cuando
/// ni siquiera `minGrupo` entra, se sigue achicando hasta `pisoAbsoluto`
/// antes de degradar, porque un grupo apretado es preferible a uno que
/// pinta fuera del panel.
///
/// `gruposPorLinea`, si no es null, fija la cantidad de columnas (por
/// ejemplo 3 en el Truco, porque tres grupos son 15 puntos: una línea
/// llena se lee de un vistazo como las malas o las buenas completas). El
/// tamaño se busca de todas formas de mayor a menor para que esa cantidad
/// entre a lo ancho y las filas resultantes entren a lo alto. Si es null,
/// el comportamiento es el de siempre: las columnas salen del espacio
/// disponible.
MatchLayout calcularLayout({
  required int puntos,
  required Size espacio,
  double minGrupo = 44,
  double maxGrupo = 96,
  double separacion = 8,
  double paso = 4,
  double pisoAbsoluto = 20,
  int? gruposPorLinea,
}) {
  final grupos = (puntos / 5).ceil();
  if (grupos <= 0) {
    return MatchLayout(tamanoGrupo: minGrupo, columnas: 0, filas: 0, separacion: separacion);
  }

  for (var tamano = maxGrupo; tamano >= pisoAbsoluto; tamano -= paso) {
    final int columnas;
    if (gruposPorLinea != null) {
      // Ancho necesario para exactamente esa cantidad de grupos por línea.
      final ancho = gruposPorLinea * tamano + (gruposPorLinea - 1) * separacion;
      if (ancho > espacio.width) continue;
      columnas = gruposPorLinea;
    } else {
      columnas = _columnasPara(tamano, espacio.width, separacion);
      if (columnas < 1) continue; // no entra ni una vez a lo ancho: probar más chico
    }
    final filas = (grupos / columnas).ceil();
    final alto = filas * tamano + (filas - 1) * separacion;
    if (alto <= espacio.height) {
      return MatchLayout(tamanoGrupo: tamano, columnas: columnas, filas: filas, separacion: separacion);
    }
  }

  // Caso degradado: el espacio es demasiado bajo, o más angosto que
  // pisoAbsoluto. Se devuelve el mínimo con una columna, garantizando al
  // menos un grupo visible, aunque pueda desbordar a lo ancho en espacios
  // muy angostos.
  final int columnasFinales;
  if (gruposPorLinea != null) {
    columnasFinales = gruposPorLinea;
  } else {
    final columnas = _columnasPara(pisoAbsoluto, espacio.width, separacion);
    columnasFinales = columnas < 1 ? 1 : columnas;
  }
  return MatchLayout(
    tamanoGrupo: pisoAbsoluto,
    columnas: columnasFinales,
    filas: (grupos / columnasFinales).ceil(),
    separacion: separacion,
  );
}

int _columnasPara(double tamano, double ancho, double separacion) {
  return ((ancho + separacion) / (tamano + separacion)).floor();
}
