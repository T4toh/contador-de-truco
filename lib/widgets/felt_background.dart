import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Mesa de paño: degradé radial más una trama diagonal muy sutil.
///
/// La trama se dibuja como una textura repetida, no línea por línea: un tile
/// de 6×6 puntos se rasteriza una sola vez y se pinta con un `ImageShader`
/// en una llamada. Dibujar las ~600 líneas con alpha en cada frame dejaba
/// los frames en ~40 ms en una tablet de gama baja (Redmi Pad SE), e
/// Impeller no cachea capas, así que un `RepaintBoundary` solo no alcanza.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-.3, -.5),
                radius: 1.2,
                colors: [
                  MesaColors.panoLuz,
                  MesaColors.panoBase,
                  MesaColors.panoSombra,
                ],
                stops: [0, .6, 1],
              ),
            ),
            child: CustomPaint(
              painter: _TramaPano(MediaQuery.maybeDevicePixelRatioOf(context) ?? 1),
              isComplex: true,
              willChange: false,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TramaPano extends CustomPainter {
  final double dpr;

  _TramaPano(this.dpr);

  /// Lado del tile en puntos lógicos. Las dos diagonales tienen este período,
  /// así que el tile empalma consigo mismo en las dos direcciones.
  static const _paso = 6.0;

  /// Un tile por densidad de pantalla; en la práctica, uno solo.
  static final _tiles = <double, ui.Image>{};

  @override
  void paint(Canvas canvas, Size size) {
    final tile = _tiles[dpr] ??= _armarTile(dpr);
    final shader = ui.ImageShader(
      tile,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.diagonal3Values(1 / dpr, 1 / dpr, 1).storage,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  static ui.Image _armarTile(double dpr) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    _dibujarLineas(canvas, const Size(_paso, _paso));
    final lado = (_paso * dpr).ceil();
    return recorder.endRecording().toImageSync(lado, lado);
  }

  /// La trama original, línea por línea. Sobre un tile de 6×6 dibuja el
  /// período completo de las dos diagonales.
  static void _dibujarLineas(Canvas canvas, Size size) {
    final clara = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    final oscura = Paint()
      ..color = Colors.black.withValues(alpha: .05)
      ..strokeWidth = 1;

    for (var x = -size.height; x < size.width; x += _paso) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), clara);
      canvas.drawLine(
        Offset(x + _paso / 2, 0),
        Offset(x + _paso / 2 - size.height, size.height),
        oscura,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TramaPano oldDelegate) => oldDelegate.dpr != dpr;
}
