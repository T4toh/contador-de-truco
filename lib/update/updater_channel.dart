import 'package:flutter/services.dart';

enum EstadoDescarga { pendiente, corriendo, pausada, exitosa, fallida }

/// Foto del estado de una descarga en `DownloadManager`.
class Descarga {
  final EstadoDescarga estado;
  final int bytesSoFar;
  final int bytesTotal;

  const Descarga({
    required this.estado,
    required this.bytesSoFar,
    required this.bytesTotal,
  });

  /// 0..1, o `null` mientras no se conoce el total.
  double? get progreso =>
      bytesTotal > 0 ? (bytesSoFar / bytesTotal).clamp(0.0, 1.0) : null;
}

/// Wrapper del `MethodChannel` hacia `UpdaterPlugin.kt`. Solo traduce.
class UpdaterChannel {
  static const canal = MethodChannel('io.github.t4toh.contadordetruco/updater');

  Future<String> currentVersionName() async =>
      (await canal.invokeMethod<String>('currentVersionName'))!;

  Future<bool> canRequestInstall() async =>
      (await canal.invokeMethod<bool>('canRequestInstall'))!;

  Future<void> openInstallSettings() =>
      canal.invokeMethod<void>('openInstallSettings');

  Future<int> enqueueDownload(Uri url) async =>
      (await canal.invokeMethod<int>('enqueueDownload', {'url': url.toString()}))!;

  Future<Descarga> queryDownload(int id) async {
    final m = (await canal.invokeMapMethod<String, Object?>(
        'queryDownload', {'id': id}))!;
    return Descarga(
      estado: switch (m['status']) {
        'pending' => EstadoDescarga.pendiente,
        'running' => EstadoDescarga.corriendo,
        'paused' => EstadoDescarga.pausada,
        'successful' => EstadoDescarga.exitosa,
        _ => EstadoDescarga.fallida,
      },
      bytesSoFar: (m['bytesSoFar'] as num? ?? 0).toInt(),
      bytesTotal: (m['bytesTotal'] as num? ?? -1).toInt(),
    );
  }

  Future<bool> verifyAndInstall(int id, String sha256) async =>
      (await canal.invokeMethod<bool>(
          'verifyAndInstall', {'id': id, 'sha256': sha256}))!;
}
