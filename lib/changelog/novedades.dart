import 'package:shared_preferences/shared_preferences.dart';

import '../update/update_checker.dart';

/// Decide si hay que mostrar el changelog al abrir: la primera vez que la app
/// arranca con una versión distinta a la última que el usuario vio.
///
/// Si no hay "última vista" puede ser una instalación limpia (no se muestra
/// nada) o un upgrade desde una versión anterior a esta función, como la
/// 1.0.2 publicada. Las distingue la fecha del último chequeo de updates,
/// que el updater guarda desde la 1.0.1: si existe, la app ya se usó antes.
class Novedades {
  static const clave = 'ultima_version_vista';

  Future<bool> hayQueMostrar(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final vista = prefs.getString(clave);
    await prefs.setString(clave, version);
    if (vista != null) return vista != version;
    return prefs.containsKey(UpdateChecker.claveUltimoChequeo);
  }
}
