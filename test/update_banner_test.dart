import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/theme/mesa_theme.dart';
import 'package:contador_de_truco/update/update_info.dart';
import 'package:contador_de_truco/update/updater_channel.dart';
import 'package:contador_de_truco/widgets/update_banner.dart';
import 'package:contador_de_truco/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final info = UpdateInfo(
    version: const Version(1, 0, 1),
    apkUrl: Uri.parse('https://example.com/app.apk'),
    sha256: 'abc',
  );

  final llamadas = <MethodCall>[];
  var cerrado = 0;

  /// Instala un handler del canal. [queries] se devuelven en orden en cada
  /// `queryDownload`; la última se repite.
  void mockCanal({
    bool permiso = true,
    List<Map<String, Object>> queries = const [],
    bool verificacion = true,
  }) {
    var i = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      llamadas.add(call);
      switch (call.method) {
        case 'canRequestInstall':
          return permiso;
        case 'openInstallSettings':
          return null;
        case 'enqueueDownload':
          return 7;
        case 'queryDownload':
          final q = queries[i.clamp(0, queries.length - 1)];
          i++;
          return q;
        case 'verifyAndInstall':
          return verificacion;
      }
      return null;
    });
  }

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        theme: mesaTheme(),
        home: Scaffold(
          body: UpdateBanner(
            info: info,
            canal: UpdaterChannel(),
            onCerrar: () => cerrado++,
          ),
        ),
      ));

  setUp(() {
    llamadas.clear();
    cerrado = 0;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, null);
  });

  testWidgets('muestra la versión nueva y "Ahora no" avisa al padre',
      (tester) async {
    mockCanal();
    await montar(tester);

    expect(find.text('Hay una versión nueva: 1.0.1'), findsOneWidget);
    await tester.tap(find.byTooltip('Ahora no'));
    expect(cerrado, 1);
  });

  testWidgets('sin permiso de instalación manda a Ajustes', (tester) async {
    mockCanal(permiso: false);
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('habilitá "Instalar apps desconocidas"'),
        findsOneWidget);
    await tester.tap(find.text('Abrir Ajustes'));
    await tester.pump();
    expect(llamadas.map((c) => c.method), contains('openInstallSettings'));
    expect(llamadas.map((c) => c.method), isNot(contains('enqueueDownload')));
  });

  testWidgets('descarga con progreso y al terminar verifica e instala',
      (tester) async {
    mockCanal(queries: [
      {'status': 'running', 'bytesSoFar': 50, 'bytesTotal': 100},
      {'status': 'successful', 'bytesSoFar': 100, 'bytesTotal': 100},
    ]);
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    // Un solo pump (no pumpAndSettle): alcanza para completar los dos awaits
    // inmediatos (canRequestInstall + enqueueDownload). pumpAndSettle acá
    // sigue pumpeando mientras el ripple del botón anima, y esos pumps de
    // 100ms se acumulan hasta pasar el segundo del timer periódico — dispara
    // el primer tick (con la respuesta "running") antes de que el test lo
    // pida explícitamente, y el pump(1s) de abajo cae en el segundo tick
    // ("successful") salteándose el estado de progreso 0.5 que se quiere
    // observar acá.
    await tester.pump();
    expect(find.text('Descargando 1.0.1…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final barra =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(barra.value, 0.5);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final verify = llamadas.singleWhere((c) => c.method == 'verifyAndInstall');
    expect(verify.arguments, {'id': 7, 'sha256': 'abc'});
    // Después de instalar el timer quedó cancelado: el test termina sin
    // "A Timer is still pending".

    expect(find.text('Actualización lista para instalar.'), findsOneWidget);
    expect(find.text('Instalar'), findsOneWidget);

    await tester.tap(find.text('Instalar'));
    await tester.pumpAndSettle();

    final verifies =
        llamadas.where((c) => c.method == 'verifyAndInstall').toList();
    expect(verifies, hasLength(2));
    expect(verifies.last.arguments, {'id': 7, 'sha256': 'abc'});
  });

  testWidgets('SHA-256 que no coincide avisa y ofrece reintentar',
      (tester) async {
    mockCanal(
      queries: [
        {'status': 'successful', 'bytesSoFar': 100, 'bytesTotal': 100},
      ],
      verificacion: false,
    );
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('La descarga se corrompió, probá de nuevo.'),
        findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('descarga fallida ofrece reintentar y reintenta', (tester) async {
    mockCanal(queries: [
      {'status': 'failed', 'bytesSoFar': 0, 'bytesTotal': -1},
    ]);
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('La descarga falló.'), findsOneWidget);

    llamadas.clear();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(llamadas.map((c) => c.method), contains('enqueueDownload'));

    // Deja el timer cancelado antes de terminar el test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('La descarga falló.'), findsOneWidget);
  });

  testWidgets(
      'un round trip lento no dispara dos instalaciones desde dos ticks',
      (tester) async {
    // queryDownload tarda 1.5s en responder "successful". El timer sigue
    // tickeando cada 1s mientras tanto: sin la guarda de re-entrada, el
    // segundo tick arrancaría su propio queryDownload/verifyAndInstall antes
    // de que el primero termine.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      llamadas.add(call);
      switch (call.method) {
        case 'canRequestInstall':
          return true;
        case 'enqueueDownload':
          return 7;
        case 'queryDownload':
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          return {'status': 'successful', 'bytesSoFar': 100, 'bytesTotal': 100};
        case 'verifyAndInstall':
          return true;
      }
      return null;
    });
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pump();

    // t=1s: primer tick, arranca el queryDownload demorado.
    await tester.pump(const Duration(seconds: 1));
    // t=2s: segundo tick. Sin la guarda arrancaría un segundo queryDownload
    // (el primero recién responde en t=2.5s); con la guarda, no hace nada.
    await tester.pump(const Duration(seconds: 1));
    // t=3s: para cuando se llega acá, el primer queryDownload ya respondió
    // (t=2.5s) y verifyAndInstall ya se llamó.
    await tester.pump(const Duration(seconds: 1));

    expect(
        llamadas.where((c) => c.method == 'verifyAndInstall').length, 1);
    expect(
        llamadas.where((c) => c.method == 'queryDownload').length, 1);
  });

  testWidgets('doble tap en Actualizar no encola dos descargas',
      (tester) async {
    // canRequestInstall tarda 500ms en responder: dos taps antes de que
    // resuelva, sin la guarda, arrancarían dos _actualizar en paralelo y
    // encolarían dos descargas.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      llamadas.add(call);
      switch (call.method) {
        case 'canRequestInstall':
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return true;
        case 'enqueueDownload':
          return 7;
        case 'queryDownload':
          return {'status': 'failed', 'bytesSoFar': 0, 'bytesTotal': -1};
        case 'verifyAndInstall':
          return true;
      }
      return null;
    });
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pump();
    await tester.tap(find.text('Actualizar'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
        llamadas.where((c) => c.method == 'enqueueDownload').length, 1);
    // Deja el timer cancelado: la descarga resolvió "failed".
    expect(find.text('La descarga falló.'), findsOneWidget);
  });

  testWidgets(
      'Ajustes que tira PlatformException muestra error, no queda colgado',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      llamadas.add(call);
      switch (call.method) {
        case 'canRequestInstall':
          return false;
        case 'openInstallSettings':
          throw PlatformException(code: 'x');
      }
      return null;
    });
    await montar(tester);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo abrir Ajustes.'), findsOneWidget);
  });

  testWidgets(
      'HomeScreen con el canal fallando arranca en silencio, sin banner',
      (tester) async {
    // El canal está mockeado pero responde con un error en cada llamada: a
    // diferencia de no mockear nada (donde el mensaje queda bufferizado sin
    // resolver nunca en testWidgets, ver task-5-report.md), acá la excepción
    // se lanza y se espera que _chequearUpdate la atrape de verdad.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(UpdaterChannel.canal, (call) async {
      throw PlatformException(code: 'sin_plugin');
    });
    await tester.pumpWidget(const ContadorDeTrucoApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(UpdateBanner), findsNothing);
    expect(find.text('Truco'), findsOneWidget);
  });
}
