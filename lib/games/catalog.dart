import 'package:flutter/material.dart';

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
);

/// Agregar un contador nuevo es agregar una entrada acá. Por ejemplo, el
/// gallo (truco de a tres) sería otra const con `participantes: [3]`.
const catalogo = <GameSpec>[truco, escoba];
