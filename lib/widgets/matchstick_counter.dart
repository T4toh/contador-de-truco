import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'matchstick_layout.dart';

/// Dibuja el puntaje como fósforos: grupos de 5 (cuatro lados de un
/// cuadrado más la diagonal), igual que anotando en un papel.
class MatchstickCounter extends StatelessWidget {
  final int points;

  const MatchstickCounter({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points <= 0) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 56,
            color: MesaColors.crema.withValues(alpha: .25),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final layout = calcularLayout(
          puntos: points,
          espacio: Size(restricciones.maxWidth, restricciones.maxHeight),
        );

        final grupos = <Widget>[];
        var restantes = points;
        var indice = 0;
        while (restantes > 0) {
          final enEste = restantes >= 5 ? 5 : restantes;
          grupos.add(SizedBox(
            width: layout.tamanoGrupo,
            height: layout.tamanoGrupo,
            child: CustomPaint(
              painter: MatchstickGroupPainter(count: enEste, semilla: indice),
            ),
          ));
          restantes -= enEste;
          indice++;
        }

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: grupos,
          ),
        );
      },
    );
  }
}

/// Pinta un grupo de hasta 5 fósforos.
class MatchstickGroupPainter extends CustomPainter {
  final int count;

  /// Índice del grupo. Alimenta la imperfección de cada fósforo para que
  /// no parezcan clonados — y es determinística, así que no titila.
  final int semilla;

  const MatchstickGroupPainter({required this.count, required this.semilla});

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide * 0.62;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final arribaIzq = Offset(cx - lado / 2, cy - lado / 2);
    final arribaDer = Offset(cx + lado / 2, cy - lado / 2);
    final abajoIzq = Offset(cx - lado / 2, cy + lado / 2);
    final abajoDer = Offset(cx + lado / 2, cy + lado / 2);

    // Orden de colocación: izquierda, arriba, derecha, abajo, diagonal.
    // El primer punto de cada par es donde va la cabeza.
    final trazos = <List<Offset>>[
      [abajoIzq, arribaIzq],
      [arribaIzq, arribaDer],
      [arribaDer, abajoDer],
      [abajoDer, abajoIzq],
      [abajoIzq, arribaDer],
    ];

    for (var i = 0; i < count && i < trazos.length; i++) {
      _fosforo(canvas, trazos[i][0], trazos[i][1], size, i);
    }
  }

  void _fosforo(Canvas canvas, Offset desde, Offset hasta, Size size, int i) {
    final base = size.shortestSide;
    final grosor = base * 0.075;
    final cabezaR = grosor * 1.15;

    final dx = hasta.dx - desde.dx;
    final dy = hasta.dy - desde.dy;
    // ±2.5° de inclinación y ±3% de largo, por fósforo.
    final angulo = math.atan2(dy, dx) + _ruido(i, 0) * 0.045;
    final largo = math.sqrt(dx * dx + dy * dy) * (1 + _ruido(i, 1) * 0.03);

    canvas.save();
    canvas.translate(desde.dx, desde.dy);
    canvas.rotate(angulo);

    final rect = Rect.fromLTWH(cabezaR * 0.4, -grosor / 2, largo, grosor);
    final palito = RRect.fromRectAndRadius(rect, Radius.circular(grosor / 2));

    // Sombra sobre el paño.
    canvas.drawRRect(
      palito.shift(Offset(grosor * 0.25, grosor * 0.45)),
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, grosor * 0.35),
    );

    // Palito con veta.
    canvas.drawRRect(
      palito,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0DCB4),
            MesaColors.maderaFosforo,
            Color(0xFFB9995F),
          ],
          stops: [0, .45, 1],
        ).createShader(rect),
    );

    // Banda de brillo en el canto superior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabezaR * 0.4, -grosor / 2, largo, grosor * 0.28),
        Radius.circular(grosor * 0.14),
      ),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );

    // Cabeza.
    final cabeza = Rect.fromCircle(center: Offset.zero, radius: cabezaR);
    canvas.drawOval(
      cabeza,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Color(0xFFEF6B4A), Color(0xFFCF3A22), Color(0xFF7D1D0F)],
          stops: [0, .5, 1],
        ).createShader(cabeza),
    );

    // Reflejo.
    canvas.drawCircle(
      Offset(-cabezaR * 0.3, -cabezaR * 0.35),
      cabezaR * 0.26,
      Paint()..color = Colors.white.withValues(alpha: .42),
    );

    canvas.restore();
  }

  /// Ruido determinístico en [-1, 1] a partir del grupo, el fósforo y el
  /// canal pedido. Determinístico es el requisito: con `Random()` sin
  /// semilla los fósforos se moverían en cada repintado.
  double _ruido(int indice, int canal) {
    final h = (semilla * 73856093) ^ (indice * 19349663) ^ (canal * 83492791);
    return ((h & 0xFFFF) / 0xFFFF) * 2 - 1;
  }

  @override
  bool shouldRepaint(covariant MatchstickGroupPainter anterior) =>
      anterior.count != count || anterior.semilla != semilla;
}
