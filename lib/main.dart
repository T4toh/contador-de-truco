import 'package:flutter/material.dart';

import 'games/catalog.dart';
import 'games/counter_screen.dart';
import 'theme/mesa_theme.dart';

void main() {
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
