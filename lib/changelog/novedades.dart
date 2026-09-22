import 'package:shared_preferences/shared_preferences.dart';

/// Decide si hay que mostrar el changelog al abrir: la primera vez que la app
/// arranca con una versión distinta a la última que el usuario vio. En una
/// instalación limpia no hay "última vista", así que no muestra nada y solo
/// la recuerda.
class Novedades {
  static const clave = 'ultima_version_vista';

  Future<bool> hayQueMostrar(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final vista = prefs.getString(clave);
    await prefs.setString(clave, version);
    return vista != null && vista != version;
  }
}
