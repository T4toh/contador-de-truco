import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import 'matchstick_counter.dart';
import 'wood_panel.dart';

/// Ancho de panel por debajo del cual se usa el nombre corto. Un panel de
/// la grilla 2x2 en un teléfono cae acá; el mismo panel en tablet, no.
const _anchoNombreLargo = 260.0;

/// Un participante: nombre, chip opcional del hito, fósforos, puntaje y
/// botón de restar. Tocar el panel suma; mantener el nombre lo edita.
class ScorePanel extends StatelessWidget {
  final String nombre;

  /// Versión abreviada del nombre, para cuando el panel es angosto. Si es
  /// null se usa [nombre] siempre, elipsado si no entra.
  final String? nombreCorto;

  final int puntaje;
  final String? chip;
  final bool chipActivo;
  final VoidCallback onSumar;
  final VoidCallback? onRestar;
  final VoidCallback onRenombrar;

  /// Cuántos grupos de fósforos se apilan en cada columna. Se reenvía a
  /// [MatchstickCounter] tal cual.
  final int? gruposPorColumna;

  const ScorePanel({
    super.key,
    required this.nombre,
    this.nombreCorto,
    required this.puntaje,
    this.chip,
    this.chipActivo = false,
    required this.onSumar,
    required this.onRestar,
    required this.onRenombrar,
    this.gruposPorColumna,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onSumar,
      child: WoodPanel(
        destacado: chipActivo,
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final ancho = restricciones.maxWidth;
            final corto = nombreCorto;
            final visible =
                corto != null && ancho < _anchoNombreLargo ? corto : nombre;

            // Las dos franjas laterales acompañan al panel en vez de
            // quedarse en un ancho fijo: en la grilla 2x2 de un teléfono,
            // 64 + 96 px fijos no dejaban lugar para los fósforos.
            final anchoBoton = (ancho * .16).clamp(44.0, 64.0);
            final anchoPuntaje = (ancho * .22).clamp(48.0, 96.0);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: onRenombrar,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  visible,
                                  style: textos.headlineMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: onRenombrar,
                                // El ícono queda chico, pero el área de toque
                                // cumple el mínimo de 44x44: al lado hay un área
                                // que suma puntos, así que errarle no puede
                                // costar un punto de más.
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: MesaColors.doradoClaro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (chip != null) _Chip(texto: chip!, activo: chipActivo),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        // El botón queda abajo a la izquierda, donde cae el pulgar.
                        SizedBox(
                          width: anchoBoton,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: FilledButton.tonal(
                              onPressed: onRestar,
                              style: FilledButton.styleFrom(
                                backgroundColor: MesaColors.brasa,
                                foregroundColor: MesaColors.crema,
                                minimumSize: const Size(44, 36),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('−'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: MatchstickCounter(
                            points: puntaje,
                            gruposPorColumna: gruposPorColumna,
                          ),
                        ),
                        // El puntaje llena el hueco de la derecha en vez de
                        // comerse una franja de alto abajo.
                        SizedBox(
                          width: anchoPuntaje,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$puntaje',
                                style: textos.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
        color: activo ? MesaColors.dorado : MesaColors.chipInactivo,
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
