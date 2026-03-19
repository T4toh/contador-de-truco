import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchstickCounter extends StatelessWidget {
  final int points;
  final int groupsPerRow;

  const MatchstickCounter({
    super.key,
    required this.points,
    this.groupsPerRow = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (points == 0) {
      return Center(
        child: Text(
          '—',
          style: GoogleFonts.raleway(
            fontSize: 60,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
    }

    int fullGroups = points ~/ 5;
    int remainingSticks = points % 5;

    List<Widget> allGroups = [];

    for (int i = 0; i < fullGroups; i++) {
      allGroups.add(const MatchstickGroup(count: 5));
    }

    if (remainingSticks > 0) {
      allGroups.add(MatchstickGroup(count: remainingSticks));
    }

    List<Widget> rows = [];
    for (int i = 0; i < allGroups.length; i += groupsPerRow) {
      int end = (i + groupsPerRow < allGroups.length)
          ? i + groupsPerRow
          : allGroups.length;
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allGroups.sublist(i, end).map((group) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: group,
            );
          }).toList(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: row,
          );
        }).toList(),
      ),
    );
  }
}

class MatchstickGroup extends StatelessWidget {
  final int count;

  const MatchstickGroup({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: MatchstickGroupPainter(count: count),
      ),
    );
  }
}

class MatchstickGroupPainter extends CustomPainter {
  final int count;

  MatchstickGroupPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final woodPaint = Paint()
      ..color = Colors.brown[400]!
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()
      ..color = Colors.redAccent[700]!
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const boxSize = 35.0;

    if (count >= 1) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY - boxSize / 2,
          centerX - boxSize / 2, centerY + boxSize / 2);
    }
    if (count >= 2) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY - boxSize / 2,
          centerX + boxSize / 2, centerY - boxSize / 2);
    }
    if (count >= 3) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX + boxSize / 2, centerY - boxSize / 2,
          centerX + boxSize / 2, centerY + boxSize / 2);
    }
    if (count >= 4) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY + boxSize / 2,
          centerX + boxSize / 2, centerY + boxSize / 2);
    }
    if (count == 5) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY + boxSize / 2,
          centerX + boxSize / 2, centerY - boxSize / 2);
    }
  }

  void _drawMatchstick(Canvas canvas, Paint woodPaint, Paint headPaint,
      double x1, double y1, double x2, double y2) {
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), woodPaint);
    headPaint.strokeWidth = 6.5;
    canvas.drawCircle(Offset(x1, y1), 3.5, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
