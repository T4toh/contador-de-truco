import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import '../update/update_info.dart';
import '../update/updater_channel.dart';

enum _Fase { aviso, sinPermiso, descargando, verificando, listo, error }

/// Aviso de versión nueva, arriba del tablero. No es modal: no interrumpe
/// una partida. Orquesta permiso → descarga → verificación → instalador.
class UpdateBanner extends StatefulWidget {
  final UpdateInfo info;
  final UpdaterChannel canal;
  final VoidCallback onCerrar;

  const UpdateBanner({
    super.key,
    required this.info,
    required this.canal,
    required this.onCerrar,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with WidgetsBindingObserver {
  _Fase _fase = _Fase.aviso;
  String _error = '';
  double? _progreso;
  int? _downloadId;
  Timer? _timer;
  bool _consultando = false;
  bool _actualizando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Vuelve de Ajustes: si ya habilitó la instalación, arranca solo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _fase == _Fase.sinPermiso) {
      _actualizar();
    }
  }

  Future<void> _actualizar() async {
    // Sin esta guarda, un doble tap en "Actualizar"/"Reintentar" (o dos
    // "resumed" seguidos volviendo de Ajustes) corre el método dos veces en
    // paralelo y encola dos descargas al mismo update.apk: la segunda borra
    // el archivo de la primera.
    if (_actualizando) return;
    _actualizando = true;
    try {
      if (!await widget.canal.canRequestInstall()) {
        _cambiar(_Fase.sinPermiso);
        return;
      }
      _downloadId = await widget.canal.enqueueDownload(widget.info.apkUrl);
      _progreso = null;
      _cambiar(_Fase.descargando);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _consultar());
    } catch (e) {
      _fallar('La descarga falló.');
    } finally {
      _actualizando = false;
    }
  }

  /// Verifica el hash y dispara el instalador de Android sobre la descarga
  /// ya encolada. La usan tanto el fin de la descarga como el botón
  /// "Instalar" de la fase `listo` (el usuario canceló el instalador, o
  /// Android lo rechazó por firma, y hay que poder reintentar sin volver a
  /// descargar).
  Future<void> _instalar() async {
    final id = _downloadId;
    if (id == null) return;
    _cambiar(_Fase.verificando);
    final ok = await widget.canal.verifyAndInstall(id, widget.info.sha256);
    if (!mounted) return;
    if (ok) {
      _cambiar(_Fase.listo);
    } else {
      _fallar('La descarga se corrompió, probá de nuevo.');
    }
  }

  Future<void> _abrirAjustes() async {
    try {
      await widget.canal.openInstallSettings();
    } catch (e) {
      _fallar('No se pudo abrir Ajustes.');
    }
  }

  Future<void> _consultar() async {
    final id = _downloadId;
    if (id == null) return;
    // El timer dispara cada 1 s sin esperar a que termine la consulta
    // anterior. Sin esta guarda, un round trip lento (o el paso a
    // "verificando" + "verifyAndInstall", que son dos awaits) puede solaparse
    // con el siguiente tick y disparar dos instalaciones de una descarga.
    if (_consultando) return;
    _consultando = true;
    try {
      final d = await widget.canal.queryDownload(id);
      if (!mounted) return;
      switch (d.estado) {
        case EstadoDescarga.exitosa:
          _timer?.cancel();
          await _instalar();
        case EstadoDescarga.fallida:
          _fallar('La descarga falló.');
        case EstadoDescarga.pendiente:
        case EstadoDescarga.corriendo:
        case EstadoDescarga.pausada:
          setState(() => _progreso = d.progreso);
      }
    } catch (e) {
      _fallar('La descarga falló.');
    } finally {
      _consultando = false;
    }
  }

  void _fallar(String mensaje) {
    _timer?.cancel();
    _error = mensaje;
    _cambiar(_Fase.error);
  }

  void _cambiar(_Fase fase) {
    if (!mounted) return;
    setState(() => _fase = fase);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estilo = textos.titleMedium?.copyWith(color: MesaColors.crema);

    return Material(
      color: MesaColors.maderaOscura,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: switch (_fase) {
            _Fase.aviso => Row(children: [
                Expanded(
                    child: Text('Hay una versión nueva: ${widget.info.version}',
                        style: estilo)),
                FilledButton(
                    onPressed: _actualizar, child: const Text('Actualizar')),
                IconButton(
                  tooltip: 'Ahora no',
                  icon: const Icon(Icons.close, color: MesaColors.crema),
                  onPressed: widget.onCerrar,
                ),
              ]),
            _Fase.sinPermiso => Row(children: [
                Expanded(
                    child: Text(
                        'Para actualizar, habilitá "Instalar apps desconocidas" '
                        'para Contador de Truco.',
                        style: estilo)),
                FilledButton(
                    onPressed: _abrirAjustes,
                    child: const Text('Abrir Ajustes')),
              ]),
            _Fase.descargando || _Fase.verificando => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      _fase == _Fase.descargando
                          ? 'Descargando ${widget.info.version}…'
                          : 'Verificando la descarga…',
                      style: estilo),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LinearProgressIndicator(
                      value: _fase == _Fase.descargando ? _progreso : null,
                      color: MesaColors.doradoClaro,
                      backgroundColor: MesaColors.chipInactivo,
                    ),
                  ),
                ],
              ),
            _Fase.listo => Row(children: [
                Expanded(
                    child: Text('Actualización lista para instalar.',
                        style: estilo)),
                FilledButton(
                    onPressed: _instalar, child: const Text('Instalar')),
                IconButton(
                  tooltip: 'Ahora no',
                  icon: const Icon(Icons.close, color: MesaColors.crema),
                  onPressed: widget.onCerrar,
                ),
              ]),
            _Fase.error => Row(children: [
                Expanded(child: Text(_error, style: estilo)),
                FilledButton(
                    onPressed: _actualizar, child: const Text('Reintentar')),
                IconButton(
                  tooltip: 'Ahora no',
                  icon: const Icon(Icons.close, color: MesaColors.crema),
                  onPressed: widget.onCerrar,
                ),
              ]),
          },
        ),
      ),
    );
  }
}
