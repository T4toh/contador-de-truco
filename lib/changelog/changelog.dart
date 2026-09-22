/// Parser mínimo de `CHANGELOG.md` (formato Keep a Changelog).
///
/// Reconoce lo que el archivo usa y nada más: `## [versión] - fecha` abre
/// una sección, `### Título` es un subtítulo, `- texto` una viñeta (las
/// líneas siguientes indentadas son su continuación). El resto —título del
/// archivo, intro, links de referencia al pie— se ignora. Sin paquete de
/// markdown: no hace falta para esto.
library;

class SeccionChangelog {
  /// "1.0.2 · 2026-09-21" o "Sin publicar".
  final String titulo;
  final List<LineaChangelog> lineas;

  const SeccionChangelog(this.titulo, this.lineas);
}

class LineaChangelog {
  final String texto;
  final bool esSubtitulo;

  const LineaChangelog.subtitulo(this.texto) : esSubtitulo = true;
  const LineaChangelog.vineta(this.texto) : esSubtitulo = false;

  @override
  bool operator ==(Object other) =>
      other is LineaChangelog &&
      other.texto == texto &&
      other.esSubtitulo == esSubtitulo;

  @override
  int get hashCode => Object.hash(texto, esSubtitulo);

  @override
  String toString() => '${esSubtitulo ? '###' : '-'} $texto';
}

List<SeccionChangelog> parsearChangelog(String markdown) {
  final secciones = <SeccionChangelog>[];
  List<LineaChangelog>? lineas;
  StringBuffer? vineta;

  void cerrarVineta() {
    if (vineta != null && lineas != null) {
      lineas.add(LineaChangelog.vineta(_limpiar(vineta.toString())));
    }
    vineta = null;
  }

  for (final cruda in markdown.split('\n')) {
    final linea = cruda.trimRight();
    if (linea.startsWith('## ')) {
      cerrarVineta();
      lineas = [];
      secciones.add(SeccionChangelog(_tituloDeSeccion(linea), lineas));
    } else if (lineas == null) {
      continue; // antes de la primera sección: título e intro
    } else if (linea.startsWith('### ')) {
      cerrarVineta();
      lineas.add(LineaChangelog.subtitulo(linea.substring(4).trim()));
    } else if (linea.startsWith('- ')) {
      cerrarVineta();
      vineta = StringBuffer(linea.substring(2).trim());
    } else if (vineta != null &&
        linea.startsWith('  ') &&
        linea.trim().isNotEmpty) {
      vineta!.write(' ${linea.trim()}');
    } else {
      cerrarVineta();
    }
  }
  cerrarVineta();
  return secciones;
}

/// `## [1.0.2] - 2026-09-21` → `1.0.2 · 2026-09-21`; `## [Sin publicar]` → `Sin publicar`.
String _tituloDeSeccion(String linea) {
  final sinAlmohadillas = linea.substring(3).trim();
  final m = RegExp(
    r'^\[([^\]]+)\](?:\s*-\s*(.+))?$',
  ).firstMatch(sinAlmohadillas);
  if (m == null) return sinAlmohadillas;
  final fecha = m.group(2);
  return fecha == null ? m.group(1)! : '${m.group(1)} · $fecha';
}

/// Saca la negrita y el código de markdown; acá se muestra como texto plano.
String _limpiar(String texto) => texto.replaceAll('**', '').replaceAll('`', '');
