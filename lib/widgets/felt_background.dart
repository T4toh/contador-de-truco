import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Mesa de paño: degradé radial más una trama diagonal muy sutil.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
        painter: _TramaPano(),
        child: child,
      ),
    );
  }
}

class _TramaPano extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final clara = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    final oscura = Paint()
      ..color = Colors.black.withValues(alpha: .05)
      ..strokeWidth = 1;

    const paso = 6.0;
    for (var x = -size.height; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), clara);
      canvas.drawLine(
          Offset(x + paso / 2, 0), Offset(x + paso / 2 - size.height, size.height), oscura);
    }
  }

  @override
  bool shouldRepaint(covariant _TramaPano oldDelegate) => false;
}
