import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: MesaColors.maderaOscura,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
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
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva Partida'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
