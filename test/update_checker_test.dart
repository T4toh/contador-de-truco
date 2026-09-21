import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contador_de_truco/update/update_checker.dart';

const _release = '''
{
  "tag_name": "v1.0.1",
  "assets": [
    {
      "name": "contador-de-truco-1.0.1.apk",
      "browser_download_url": "https://example.com/app.apk",
      "digest": "sha256:abc123"
    }
  ]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ahora = DateTime(2026, 9, 21, 12);

  /// Un fetch que cuenta cuántas veces lo llamaron y devuelve [cuerpo].
  ({Fetch fetch, List<Uri> llamadas}) fetchFalso(String cuerpo) {
    final llamadas = <Uri>[];
    return (
      fetch: (url) async {
        llamadas.add(url);
        return cuerpo;
      },
      llamadas: llamadas,
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('release mayor que la instalada → hay update', () async {
    final f = fetchFalso(_release);
    final checker = UpdateChecker(
        versionActual: '1.0.0', fetch: f.fetch, ahora: () => ahora);

    final info = await checker.check();

    expect(info, isNotNull);
    expect(info!.version.toString(), '1.0.1');
    expect(f.llamadas.single, Uri.parse(UpdateChecker.releaseUrl));
  });

  test('release igual o menor → no hay update', () async {
    for (final local in ['1.0.1', '1.0.2', '2.0.0']) {
      final checker = UpdateChecker(
          versionActual: local,
          fetch: fetchFalso(_release).fetch,
          ahora: () => ahora);
      SharedPreferences.setMockInitialValues({});
      expect(await checker.check(), isNull, reason: 'local $local');
    }
  });

  test('tag viejo sin formato (v0.0.2) queda por debajo → no hay update',
      () async {
    final viejo = _release.replaceFirst('v1.0.1', 'v0.0.2');
    final checker = UpdateChecker(
        versionActual: '1.0.0',
        fetch: fetchFalso(viejo).fetch,
        ahora: () => ahora);
    expect(await checker.check(), isNull);
  });

  test('JSON sin asset .apk → no hay update', () async {
    final checker = UpdateChecker(
        versionActual: '1.0.0',
        fetch: fetchFalso('{"tag_name":"v9.9.9","assets":[]}').fetch,
        ahora: () => ahora);
    expect(await checker.check(), isNull);
  });

  test('último chequeo hace menos de 24 h → no toca la red', () async {
    SharedPreferences.setMockInitialValues({
      UpdateChecker.claveUltimoChequeo:
          ahora.subtract(const Duration(hours: 23)).millisecondsSinceEpoch,
    });
    final f = fetchFalso(_release);
    final checker = UpdateChecker(
        versionActual: '1.0.0', fetch: f.fetch, ahora: () => ahora);

    expect(await checker.check(), isNull);
    expect(f.llamadas, isEmpty);
  });

  test('último chequeo hace más de 24 h → consulta y guarda el timestamp',
      () async {
    SharedPreferences.setMockInitialValues({
      UpdateChecker.claveUltimoChequeo:
          ahora.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
    });
    final f = fetchFalso(_release);
    final checker = UpdateChecker(
        versionActual: '1.0.0', fetch: f.fetch, ahora: () => ahora);

    expect(await checker.check(), isNotNull);
    expect(f.llamadas, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(UpdateChecker.claveUltimoChequeo),
        ahora.millisecondsSinceEpoch);
  });

  test('el fetch tira (sin red) → null, sin excepción, y guarda el timestamp',
      () async {
    final checker = UpdateChecker(
      versionActual: '1.0.0',
      fetch: (_) async => throw Exception('sin red'),
      ahora: () => ahora,
    );

    expect(await checker.check(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(UpdateChecker.claveUltimoChequeo),
        ahora.millisecondsSinceEpoch);
  });

  test('JSON inválido → null, sin excepción', () async {
    final checker = UpdateChecker(
        versionActual: '1.0.0',
        fetch: fetchFalso('<html>rate limited</html>').fetch,
        ahora: () => ahora);
    expect(await checker.check(), isNull);
  });

  test('versionActual que no parsea → null, sin tocar la red', () async {
    final f = fetchFalso(_release);
    final checker = UpdateChecker(
        versionActual: 'debug', fetch: f.fetch, ahora: () => ahora);
    expect(await checker.check(), isNull);
    expect(f.llamadas, isEmpty);
  });
}
