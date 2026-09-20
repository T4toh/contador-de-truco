import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'matchstick_counter.dart';
import 'wood_panel.dart';

/// Un participante: nombre, chip opcional del hito, fósforos, puntaje y
/// botón de restar. Tocar el panel suma; mantener el nombre lo edita.
class ScorePanel extends StatelessWidget {
  final String nombre;
  final int puntaje;
  final String? chip;
  final bool chipActivo;
  final VoidCallback onSumar;
  final VoidCallback? onRestar;
  final VoidCallback onRenombrar;

  const ScorePanel({
    super.key,
    required this.nombre,
    required this.puntaje,
    this.chip,
    this.chipActivo = false,
    required this.onSumar,
    required this.onRestar,
    required this.onRenombrar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onSumar,
      child: WoodPanel(
        destacado: chipActivo,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onLongPress: onRenombrar,
                child: Text(
                  nombre,
                  style: textos.headlineMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (chip != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _Chip(texto: chip!, activo: chipActivo),
              ),
            Expanded(child: MatchstickCounter(points: puntaje)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton.tonal(
                    onPressed: onRestar,
                    style: FilledButton.styleFrom(
                      backgroundColor: MesaColors.brasa,
                      foregroundColor: MesaColors.crema,
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('−'),
                  ),
                  Text('$puntaje', style: textos.displaySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;

  const _Chip({required this.texto, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? MesaColors.dorado : Colors.black.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: MesaColors.dorado, width: 1),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              color: activo ? MesaColors.maderaBorde : MesaColors.doradoClaro,
            ),
      ),
    );
  }
}
