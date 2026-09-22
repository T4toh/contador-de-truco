import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generala_game.dart';

/// La partida en curso, como un solo JSON. Forma distinta a la de los
/// contadores, así que no pasa por GameStorage ni por su schema_version.
class GeneralaStorage {
  static const _clave = 'generala_partida';

  Future<void> guardar(GeneralaGame juego) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(juego.toJson()));
  }

  /// Si lo guardado no parsea, partida nueva. Nunca una pantalla en blanco.
  Future<GeneralaGame> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    final juego = GeneralaGame.desdeJson(texto);
    if (juego == null && texto != null) {
      debugPrint('Generala: partida guardada inválida, se arranca de cero');
    }
    return juego ?? GeneralaGame.nueva();
  }
}
