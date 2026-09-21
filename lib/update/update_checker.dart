import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'update_info.dart';

/// Trae el cuerpo de [url] como texto. Se inyecta en tests.
typedef Fetch = Future<String> Function(Uri url);

/// Pregunta a GitHub si hay una release más nueva que la instalada.
///
/// Sin dependencia de widgets, igual que `ScoreGame`: se testea directo.
/// Nunca lanza: cualquier falla (sin red, rate limit, JSON raro) es `null`.
class UpdateChecker {
  static const releaseUrl =
      'https://api.github.com/repos/T4toh/contador-de-truco/releases/latest';
  static const claveUltimoChequeo = 'update_last_check';
  static const intervalo = Duration(hours: 24);

  final String versionActual;
  final Fetch _fetch;
  final DateTime Function() _ahora;

  UpdateChecker({
    required this.versionActual,
    Fetch? fetch,
    DateTime Function()? ahora,
  })  : _fetch = fetch ?? _fetchHttp,
        _ahora = ahora ?? DateTime.now;

  /// Devuelve la release nueva, o `null` si no hay, si el último chequeo fue
  /// hace menos de [intervalo], o si algo falló.
  Future<UpdateInfo?> check() async {
    final local = Version.parse(versionActual);
    if (local == null) {
      debugPrint('Updater: versionName "$versionActual" no parsea');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final ahora = _ahora();
    final ultimo = prefs.getInt(claveUltimoChequeo);
    if (ultimo != null &&
        ahora.difference(DateTime.fromMillisecondsSinceEpoch(ultimo)) <
            intervalo) {
      return null;
    }

    // Se guarda antes del resultado: una falla también cuenta como intento,
    // y se reintenta al día siguiente. Evita martillar la API sin red.
    await prefs.setInt(claveUltimoChequeo, ahora.millisecondsSinceEpoch);

    try {
      final cuerpo = await _fetch(Uri.parse(releaseUrl));
      final json = jsonDecode(cuerpo) as Map<String, dynamic>;
      final info = UpdateInfo.fromReleaseJson(json);
      if (info == null || !(info.version > local)) return null;
      if (info.apkUrl.scheme != 'https') {
        debugPrint('Updater: apkUrl no es https: ${info.apkUrl}');
        return null;
      }
      return info;
    } catch (e) {
      debugPrint('Updater: no se pudo chequear la release: $e');
      return null;
    }
  }

  /// GitHub rechaza requests sin `User-Agent` con 403.
  static Future<String> _fetchHttp(Uri url) async {
    final cliente = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await cliente.getUrl(url);
      req.headers.set(HttpHeaders.userAgentHeader, 'contador-de-truco');
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}', uri: url);
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      cliente.close();
    }
  }
}
