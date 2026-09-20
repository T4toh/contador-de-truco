import 'package:shared_preferences/shared_preferences.dart';

import 'game_spec.dart';
import 'score_game.dart';

/// Guarda y lee partidas, y migra los esquemas viejos.
///
/// Esquema actual, prefijado por `spec.id`:
///   `<id>_tope` · `<id>_empezada` · `<id>_participantes`
///   `<id>_score_$i` · `<id>_name_$i`
class GameStorage {
  static const _claveVersion = 'schema_version';
  static const _versionActual = 2;

  /// Lleva lo guardado al esquema actual. Idempotente.
  Future<void> migrar() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_claveVersion) ?? 0) >= _versionActual) return;

    await _migrarLegacySinPrefijo(prefs);
    await _migrarTrucoV1(prefs);
    await _migrarEscobaV1(prefs);

    await prefs.setInt(_claveVersion, _versionActual);
  }

  /// v0: claves sin prefijo, de cuando la app tenía un solo juego.
  Future<void> _migrarLegacySinPrefijo(SharedPreferences prefs) async {
    if (!prefs.containsKey('gameStarted')) return;

    await prefs.setInt('truco_scoreA', prefs.getInt('scoreA') ?? 0);
    await prefs.setInt('truco_scoreB', prefs.getInt('scoreB') ?? 0);
    await prefs.setInt('truco_maxScore', prefs.getInt('maxScore') ?? 30);
    await prefs.setString(
        'truco_teamAName', prefs.getString('teamAName') ?? 'Nosotros');
    await prefs.setString(
        'truco_teamBName', prefs.getString('teamBName') ?? 'Ellos');
    await prefs.setBool(
        'truco_gameStarted', prefs.getBool('gameStarted') ?? false);

    for (final k in [
      'scoreA',
      'scoreB',
      'maxScore',
      'teamAName',
      'teamBName',
      'gameStarted',
    ]) {
      await prefs.remove(k);
    }
  }

  /// v1 de Truco: dos equipos A/B con nombres propios.
  Future<void> _migrarTrucoV1(SharedPreferences prefs) async {
    if (!prefs.containsKey('truco_gameStarted')) return;

    await prefs.setInt('truco_score_0', prefs.getInt('truco_scoreA') ?? 0);
    await prefs.setInt('truco_score_1', prefs.getInt('truco_scoreB') ?? 0);
    await prefs.setString(
        'truco_name_0', prefs.getString('truco_teamAName') ?? 'Nosotros');
    await prefs.setString(
        'truco_name_1', prefs.getString('truco_teamBName') ?? 'Ellos');
    await prefs.setInt('truco_tope', prefs.getInt('truco_maxScore') ?? 30);
    await prefs.setBool(
        'truco_empezada', prefs.getBool('truco_gameStarted') ?? false);
    await prefs.setInt('truco_participantes', 2);

    for (final k in [
      'truco_scoreA',
      'truco_scoreB',
      'truco_maxScore',
      'truco_teamAName',
      'truco_teamBName',
      'truco_gameStarted',
    ]) {
      await prefs.remove(k);
    }
  }

  /// v1 de Escoba: score_$i y name_$i ya coinciden; cambian los otros.
  Future<void> _migrarEscobaV1(SharedPreferences prefs) async {
    if (!prefs.containsKey('escoba_gameStarted')) return;

    await prefs.setInt(
        'escoba_participantes', prefs.getInt('escoba_playerCount') ?? 2);
    await prefs.setBool(
        'escoba_empezada', prefs.getBool('escoba_gameStarted') ?? false);
    await prefs.setInt('escoba_tope', 15);

    for (final k in ['escoba_playerCount', 'escoba_gameStarted']) {
      await prefs.remove(k);
    }
  }

  Future<void> guardar(ScoreGame juego) async {
    final prefs = await SharedPreferences.getInstance();
    final id = juego.spec.id;

    await prefs.setInt('${id}_tope', juego.tope);
    await prefs.setBool('${id}_empezada', juego.empezada);
    await prefs.setInt('${id}_participantes', juego.participantes);
    for (var i = 0; i < juego.participantes; i++) {
      await prefs.setInt('${id}_score_$i', juego.puntajes[i]);
      await prefs.setString('${id}_name_$i', juego.nombres[i]);
    }
  }

  Future<ScoreGame> cargar(GameSpec spec) async {
    final prefs = await SharedPreferences.getInstance();
    final id = spec.id;

    final guardados =
        prefs.getInt('${id}_participantes') ?? spec.participantes.first;
    // Nunca confiar en el número persistido: puede venir de una versión
    // anterior con más participantes de los que este spec sabe nombrar.
    final cuantos = guardados.clamp(1, spec.nombresPorDefecto.length);
    final nombresBase = spec.nombresPorDefecto.take(cuantos).toList();

    return ScoreGame(
      spec: spec,
      tope: prefs.getInt('${id}_tope') ?? spec.topes.first,
      empezada: prefs.getBool('${id}_empezada') ?? false,
      puntajes: List.generate(
        cuantos,
        (i) => prefs.getInt('${id}_score_$i') ?? 0,
      ),
      nombres: List.generate(
        cuantos,
        (i) => prefs.getString('${id}_name_$i') ?? nombresBase[i],
      ),
    );
  }
}
