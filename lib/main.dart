import 'package:flutter/material.dart';

import 'games/catalog.dart';
import 'games/counter_screen.dart';
import 'games/game_storage.dart';
import 'theme/mesa_theme.dart';

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
      title: 'Contador de Truco',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seleccionado,
        children: [
          for (final spec in catalogo) CounterScreen(spec: spec),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seleccionado,
        onDestinationSelected: (i) => setState(() => _seleccionado = i),
        destinations: [
          for (final spec in catalogo)
            NavigationDestination(icon: Icon(spec.icono), label: spec.titulo),
        ],
      ),
    );
  }
}
