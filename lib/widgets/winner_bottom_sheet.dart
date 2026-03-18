import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WinnerBottomSheet extends StatelessWidget {
  final String winnerName;
  final VoidCallback onReset;

  const WinnerBottomSheet({
    super.key,
    required this.winnerName,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 100),
          ),
          const SizedBox(height: 20),
          Text(
            '¡GANÓ $winnerName!',
            style: GoogleFonts.raleway(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Nueva Partida',
              style: GoogleFonts.raleway(fontSize: 18),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
