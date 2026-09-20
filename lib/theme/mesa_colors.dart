import 'package:flutter/material.dart';

/// Paleta de la dirección visual "paño y madera".
///
/// Los valores son fijos a propósito: `ColorScheme.fromSeed` fue
/// exactamente lo que produjo la paleta pastel que se está reemplazando.
abstract final class MesaColors {
  /// Fondo de mesa.
  static const panoBase = Color(0xFF1D4732);
  static const panoLuz = Color(0xFF2F6B4A);
  static const panoSombra = Color(0xFF143327);

  /// Paneles de jugador.
  static const maderaClara = Color(0xFF7A4F2C);
  static const maderaOscura = Color(0xFF5D3A1F);
  static const maderaBorde = Color(0xFF3D2513);

  /// Texto sobre madera.
  static const crema = Color(0xFFF2E3C8);

  /// Acentos.
  static const dorado = Color(0xFFA8813C);
  static const doradoClaro = Color(0xFFF6D98A);

  /// Cabezas de fósforo y botón restar.
  static const brasa = Color(0xFFC0392B);

  /// Palito del fósforo.
  static const maderaFosforo = Color(0xFFDCC294);

  /// Madera del panel cuando cruza el hito.
  static const maderaDestacada = Color(0xFF8E5E34);

  /// Sombra proyectada de los paneles sobre el paño.
  static const sombraPanel = Color(0x73000000);

  /// Fondo del chip cuando el hito todavía no se cruzó.
  static const chipInactivo = Color(0x40000000);
}
