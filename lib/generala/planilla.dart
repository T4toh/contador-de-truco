import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import '../widgets/wood_panel.dart';
import 'generala_game.dart';
import 'reglas.dart';

/// Ancho de columna por debajo del cual se usan nombres y etiquetas cortas.
const _anchoColumnaLarga = 72.0;

/// La tabla: casillas en filas, jugadores en columnas, total abajo.
/// Tocar una celda llama a [onCelda]; tocar o mantener un nombre, a [onRenombrar].
class Planilla extends StatelessWidget {
  final GeneralaGame juego;
  final void Function(int jugador, Casilla casilla) onCelda;
  final void Function(int jugador) onRenombrar;

  const Planilla({
    super.key,
    required this.juego,
    required this.onCelda,
    required this.onRenombrar,
  });

  @override
  Widget build(BuildContext context) {
    return WoodPanel(
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final n = juego.participantes;
          // Primero se decide el ancho de las etiquetas, después el de las
          // columnas: con 6 jugadores en un teléfono todo se achica.
          final anchoEtiqueta = restricciones.maxWidth / (n + 1.6);
          final angosto = anchoEtiqueta < _anchoColumnaLarga;
          final etiquetas = angosto ? 36.0 : 56.0;

          return Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: Column(
              children: [
                Expanded(child: _cabecera(context, etiquetas, angosto)),
                for (final c in Casilla.values)
                  Expanded(child: _fila(context, c, etiquetas, angosto)),
                Expanded(child: _total(context, etiquetas)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecera(BuildContext context, double etiquetas, bool angosto) {
    final estilo = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: MesaColors.doradoClaro);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MesaColors.dorado)),
      ),
      child: Row(
        children: [
          SizedBox(width: etiquetas),
          for (var j = 0; j < juego.participantes; j++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onRenombrar(j),
                onLongPress: () => onRenombrar(j),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _nombre(j, angosto),
                        style: estilo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!angosto) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: MesaColors.doradoClaro,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _nombre(int j, bool angosto) {
    final nombre = juego.nombres[j];
    final deFabrica = nombre == nombresPorDefecto[j];
    return angosto && deFabrica ? nombresCortos[j] : nombre;
  }

  Widget _fila(
      BuildContext context, Casilla c, double etiquetas, bool angosto) {
    final textos = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MesaColors.crema.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: etiquetas,
            child: Text(
              c.simbolo,
              style: c.numero != null
                  ? textos.titleMedium?.copyWith(fontSize: 26)
                  : textos.titleMedium,
              maxLines: 1,
            ),
          ),
          for (var j = 0; j < juego.participantes; j++)
            Expanded(child: _celda(context, j, c)),
        ],
      ),
    );
  }

  Widget _celda(BuildContext context, int j, Casilla c) {
    final valor = juego.valor(j, c);
    final textos = Theme.of(context).textTheme;

    final String texto;
    final Color color;
    if (valor == null) {
      texto = '·';
      color = MesaColors.crema.withValues(alpha: 0.35);
    } else if (valor == 0) {
      texto = '✕';
      color = MesaColors.brasa;
    } else {
      texto = '$valor';
      color = (c.jugadaPara(valor)?.servida ?? false)
          ? MesaColors.doradoClaro
          : MesaColors.crema;
    }

    return GestureDetector(
      key: ValueKey('celda-$j-${c.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onCelda(j, c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: MesaColors.crema.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: textos.titleMedium?.copyWith(color: color),
        ),
      ),
    );
  }

  Widget _total(BuildContext context, double etiquetas) {
    final estilo = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: MesaColors.doradoClaro,
          fontWeight: FontWeight.w700,
        );
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MesaColors.dorado, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(width: etiquetas, child: Text('Total', style: estilo)),
          for (var j = 0; j < juego.participantes; j++)
            Expanded(
              child: Center(child: Text('${juego.total(j)}', style: estilo)),
            ),
        ],
      ),
    );
  }
}
