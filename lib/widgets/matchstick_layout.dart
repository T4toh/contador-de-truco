import 'dart:math' as math;
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
/// Sin `gruposPorColumna` los grupos van en un solo eje: todos en una fila
/// o todos en una columna, el que deje el grupo más grande. Mezclar los dos
/// ejes deja un bloque irregular (tres grupos como 2+1) que se lee peor y
/// aprovecha menos el panel. Solo si ni siquiera el mejor eje llega a
/// `pisoAbsoluto` se cae a la grilla, que reparte en dos ejes para no
/// desbordar.
///
/// `gruposPorColumna`, si no es null, fija la cantidad de filas (por
/// ejemplo 3 en el Truco, porque tres grupos son 15 puntos: una columna
/// llena se lee de un vistazo como las malas o las buenas completas). El
/// tamaño se busca de todas formas de mayor a menor para que esa cantidad
/// entre a lo alto y las columnas resultantes entren a lo ancho.
MatchLayout calcularLayout({
  required int puntos,
  required Size espacio,
  double minGrupo = 44,
  double maxGrupo = 96,
  double separacion = 8,
  double paso = 4,
  double pisoAbsoluto = 20,
  int? gruposPorColumna,
}) {
  final grupos = (puntos / 5).ceil();
  if (grupos <= 0) {
    return MatchLayout(tamanoGrupo: minGrupo, columnas: 0, filas: 0, separacion: separacion);
  }

  if (gruposPorColumna == null) {
    final eje = _ejeUnico(grupos, espacio, separacion, maxGrupo, pisoAbsoluto);
    if (eje != null) return eje;
  }

  for (var tamano = maxGrupo; tamano >= pisoAbsoluto; tamano -= paso) {
    final int columnas;
    final int filas;
    if (gruposPorColumna != null) {
      // Filas fijas por la cantidad pedida, sin pasarse de la cantidad de
      // grupos (un juego a 5 puntos no reclama tres filas de una).
      filas = gruposPorColumna < grupos ? gruposPorColumna : grupos;
      columnas = (grupos / filas).ceil();
      final anchoNecesario = columnas * tamano + (columnas - 1) * separacion;
      if (anchoNecesario > espacio.width) continue;
    } else {
      columnas = _columnasPara(tamano, espacio.width, separacion);
      if (columnas < 1) continue; // no entra ni una vez a lo ancho: probar más chico
      filas = (grupos / columnas).ceil();
    }
    final alto = filas * tamano + (filas - 1) * separacion;
    if (alto <= espacio.height) {
      return MatchLayout(tamanoGrupo: tamano, columnas: columnas, filas: filas, separacion: separacion);
    }
  }

  // Caso degradado: el espacio es demasiado bajo, o más angosto que
  // pisoAbsoluto. Se devuelve el mínimo con una columna, garantizando al
  // menos un grupo visible, aunque pueda desbordar a lo ancho en espacios
  // muy angostos.
  final int filasFinales;
  final int columnasFinales;
  if (gruposPorColumna != null) {
    filasFinales = gruposPorColumna < grupos ? gruposPorColumna : grupos;
    columnasFinales = (grupos / filasFinales).ceil();
  } else {
    final columnas = _columnasPara(pisoAbsoluto, espacio.width, separacion);
    columnasFinales = columnas < 1 ? 1 : columnas;
    filasFinales = (grupos / columnasFinales).ceil();
  }
  return MatchLayout(
    tamanoGrupo: pisoAbsoluto,
    columnas: columnasFinales,
    filas: filasFinales,
    separacion: separacion,
  );
}

/// Todos los grupos en una fila o todos en una columna, el que permita el
/// grupo más grande. Devuelve null si ni el mejor de los dos llega a
/// `pisoAbsoluto`: ahí el eje único no entra y decide la grilla.
MatchLayout? _ejeUnico(
  int grupos,
  Size espacio,
  double separacion,
  double maxGrupo,
  double pisoAbsoluto,
) {
  final huecos = (grupos - 1) * separacion;
  // En una fila el límite a lo ancho se reparte entre los grupos y el alto
  // lo toma uno solo; en una columna es al revés.
  final enFila = math.min((espacio.width - huecos) / grupos, espacio.height);
  final enColumna = math.min((espacio.height - huecos) / grupos, espacio.width);

  // Empate a favor de la fila: es como se anota en un papel.
  final horizontal = enFila >= enColumna;
  final tamano = (horizontal ? enFila : enColumna).floorToDouble();
  if (tamano < pisoAbsoluto) return null;

  return MatchLayout(
    tamanoGrupo: tamano > maxGrupo ? maxGrupo : tamano,
    columnas: horizontal ? grupos : 1,
    filas: horizontal ? 1 : grupos,
    separacion: separacion,
  );
}

int _columnasPara(double tamano, double ancho, double separacion) {
  return ((ancho + separacion) / (tamano + separacion)).floor();
}
