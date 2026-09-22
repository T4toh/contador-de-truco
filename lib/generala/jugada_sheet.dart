import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'reglas.dart';

/// Fichas para cargar una celda: solo los valores que esa casilla admite.
/// Un toque anota y cierra. `onElegir(null)` borra la celda.
class JugadaSheet extends StatelessWidget {
  final Casilla casilla;
  final String jugador;

  /// Si la celda ya tenía valor, se ofrece "Borrar".
  final bool tieneValor;
  final void Function(Jugada? jugada) onElegir;

  const JugadaSheet({
    super.key,
    required this.casilla,
    required this.jugador,
    required this.tieneValor,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: MesaColors.maderaOscura,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: MesaColors.dorado, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(casilla.etiqueta, style: textos.headlineMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    jugador,
                    style: textos.labelLarge?.copyWith(
                      color: MesaColors.doradoClaro,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final j in casilla.opciones) _ficha(context, j),
                if (tieneValor)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onElegir(null);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MesaColors.crema,
                      side: const BorderSide(color: MesaColors.dorado),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: Text('Borrar', style: textos.labelLarge),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ficha(BuildContext context, Jugada j) {
    final esTachar = identical(j, tachar);
    final fondo = esTachar
        ? MesaColors.brasa
        : j.servida
        ? MesaColors.dorado
        : MesaColors.maderaClara;
    final frente = j.servida && !esTachar
        ? MesaColors.maderaBorde
        : MesaColors.crema;
    return FilledButton.tonal(
      onPressed: () {
        Navigator.pop(context);
        onElegir(j);
      },
      style: FilledButton.styleFrom(
        backgroundColor: fondo,
        foregroundColor: frente,
        minimumSize: const Size(72, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: MesaColors.dorado),
        ),
      ),
      child: Text(
        j.etiqueta,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: frente),
      ),
    );
  }
}
