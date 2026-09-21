import 'package:flutter/material.dart';

import 'counter_screen.dart';
import 'game_spec.dart';

const truco = GameSpec(
  id: 'truco',
  titulo: 'Truco',
  icono: Icons.style,
  participantes: [2],
  topes: [15, 30],
  etiquetasTope: {15: 'A MALAS', 30: 'A BUENAS'},
  nombresPorDefecto: ['Nosotros', 'Ellos'],
  hito: Hito(
    en: 15,
    soloSiTope: 30,
    antes: 'EN LAS MALAS',
    despues: 'EN LAS BUENAS',
  ),
  gruposPorColumna: 3,
);

const escoba = GameSpec(
  id: 'escoba',
  titulo: 'Escoba del 15',
  icono: Icons.grid_view,
  participantes: [2, 3, 4],
  topes: [15],
  nombresPorDefecto: ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'],
  nombresCortos: ['J#1', 'J#2', 'J#3', 'J#4'],
);

/// Una pestaña de la app: qué mostrar en la barra y qué pantalla montar.
///
/// Los contadores (Truco, Escoba) se describen con un GameSpec y comparten
/// CounterScreen. Un juego con otro modelo, como Generala, trae su pantalla.
class Juego {
  final String titulo;
  final IconData icono;
  final Widget Function(String? version) pantalla;

  const Juego({
    required this.titulo,
    required this.icono,
    required this.pantalla,
  });

  Juego.contador(GameSpec spec)
      : titulo = spec.titulo,
        icono = spec.icono,
        pantalla = ((version) =>
            CounterScreen(key: ValueKey(spec.id), spec: spec, version: version));
}

/// Agregar un juego es agregar una entrada acá. Un contador nuevo —el gallo,
/// truco de a tres— sería otro GameSpec con `participantes: [3]` envuelto en
/// `Juego.contador`.
final catalogo = <Juego>[
  Juego.contador(truco),
  Juego.contador(escoba),
];
