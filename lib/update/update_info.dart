/// Versión semántica `X.Y.Z`. Se compara componente a componente.
class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;

  const Version(this.major, this.minor, this.patch);

  static final _patron = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(\+\d+)?$');

  /// Acepta `v1.0.1`, `1.0.1` y `1.0.1+3` (el build se ignora: Android lo
  /// compara por su cuenta como `versionCode`). Cualquier otra cosa → null.
  static Version? parse(String texto) {
    final m = _patron.firstMatch(texto.trim());
    if (m == null) return null;
    return Version(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  @override
  int compareTo(Version otra) {
    if (major != otra.major) return major.compareTo(otra.major);
    if (minor != otra.minor) return minor.compareTo(otra.minor);
    return patch.compareTo(otra.patch);
  }

  bool operator >(Version otra) => compareTo(otra) > 0;

  @override
  bool operator ==(Object other) =>
      other is Version && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Lo que hace falta saber de una release para ofrecerla como update.
class UpdateInfo {
  final Version version;
  final Uri apkUrl;

  /// Hex en minúsculas, sin el prefijo `sha256:` que trae la API.
  final String sha256;

  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.sha256,
  });

  /// Parsea el JSON de `GET /repos/{owner}/{repo}/releases/latest`.
  /// Devuelve null si falta cualquier pieza: tag que no parsea, sin asset
  /// `.apk`, o sin `digest`. Sin hash no se instala nada.
  static UpdateInfo? fromReleaseJson(Map<String, dynamic> json) {
    final version = Version.parse(json['tag_name'] as String? ?? '');
    if (version == null) return null;

    final assets = (json['assets'] as List?) ?? const [];
    for (final asset in assets.cast<Map<String, dynamic>>()) {
      final nombre = asset['name'] as String? ?? '';
      if (!nombre.endsWith('.apk')) continue;

      final url = asset['browser_download_url'] as String?;
      final digest = asset['digest'] as String?;
      if (url == null || digest == null) return null;
      if (!digest.startsWith('sha256:')) return null;

      return UpdateInfo(
        version: version,
        apkUrl: Uri.parse(url),
        sha256: digest.substring('sha256:'.length).toLowerCase(),
      );
    }
    return null;
  }
}
