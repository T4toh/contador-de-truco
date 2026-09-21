import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/update/updater_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final llamadas = <MethodCall>[];

  setUp(() {
    llamadas.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      llamadas.add(call);
      switch (call.method) {
        case 'currentVersionName':
          return '1.0.0';
        case 'canRequestInstall':
          return false;
        case 'openInstallSettings':
          return null;
        case 'enqueueDownload':
          return 42;
        case 'queryDownload':
          return {'status': 'running', 'bytesSoFar': 25, 'bytesTotal': 100};
        case 'verifyAndInstall':
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, null);
  });

  test('traduce cada método y sus argumentos', () async {
    final canal = UpdaterChannel();

    expect(await canal.currentVersionName(), '1.0.0');
    expect(await canal.canRequestInstall(), isFalse);
    await canal.openInstallSettings();
    expect(await canal.enqueueDownload(Uri.parse('https://x/app.apk')), 42);
    expect(await canal.verifyAndInstall(42, 'abc'), isTrue);

    expect(llamadas.map((c) => c.method), [
      'currentVersionName',
      'canRequestInstall',
      'openInstallSettings',
      'enqueueDownload',
      'verifyAndInstall',
    ]);
    expect(llamadas[3].arguments, {'url': 'https://x/app.apk'});
    expect(llamadas[4].arguments, {'id': 42, 'sha256': 'abc'});
  });

  test('queryDownload arma un Descarga con progreso', () async {
    final d = await UpdaterChannel().queryDownload(42);
    expect(d.estado, EstadoDescarga.corriendo);
    expect(d.progreso, 0.25);
    expect(llamadas.single.arguments, {'id': 42});
  });

  test('progreso es null si no se conoce el total', () {
    const d = Descarga(
        estado: EstadoDescarga.pendiente, bytesSoFar: 0, bytesTotal: -1);
    expect(d.progreso, isNull);
  });
}
