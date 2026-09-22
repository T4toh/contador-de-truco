import 'package:flutter/material.dart';

import 'games/catalog.dart';
import 'games/game_storage.dart';
import 'theme/mesa_theme.dart';
import 'update/update_checker.dart';
import 'update/update_info.dart';
import 'update/updater_channel.dart';
import 'widgets/update_banner.dart';

Future<void> main() async {
  // La migración corre una sola vez, antes de que exista cualquier pantalla:
  // dos CounterScreen montados a la vez la ejecutarían en paralelo y podrían
  // pisarse entre sí.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await GameStorage().migrar();
  } catch (e, stack) {
    // Si la migración falla, se pierde la partida vieja pero la app abre.
    // Preferible a una pantalla en blanco.
    debugPrint('Falló la migración de datos guardados: $e\n$stack');
  }
  runApp(const ContadorDeTrucoApp());
}

class ContadorDeTrucoApp extends StatelessWidget {
  const ContadorDeTrucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulpero',
      theme: mesaTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _seleccionado = 0;
  final _canal = UpdaterChannel();
  UpdateInfo? _update;
  String? _version;

  @override
  void initState() {
    super.initState();
    // Nunca en main(): ahí ya está la migración, y la red no puede frenar
    // el arranque. Cualquier falla acá es silencio.
    WidgetsBinding.instance.addPostFrameCallback((_) => _chequearUpdate());
  }

  Future<void> _chequearUpdate() async {
    try {
      final version = await _canal.currentVersionName();
      if (mounted) setState(() => _version = version);
      final info = await UpdateChecker(versionActual: version).check();
      if (info != null && mounted) setState(() => _update = info);
    } catch (e) {
      // En tests y en plataformas sin el plugin no hay canal: no pasa nada.
      debugPrint('Updater: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    return Scaffold(
      body: Column(
        children: [
          if (update != null)
            UpdateBanner(
              info: update,
              canal: _canal,
              onCerrar: () => setState(() => _update = null),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: update != null,
              child: IndexedStack(
                index: _seleccionado,
                children: [
                  for (final juego in catalogo) juego.pantalla(_version),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seleccionado,
        onDestinationSelected: (i) => setState(() => _seleccionado = i),
        destinations: [
          for (final juego in catalogo)
            NavigationDestination(icon: Icon(juego.icono), label: juego.titulo),
        ],
      ),
    );
  }
}
