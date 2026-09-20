import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

class GameHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback onReiniciar;

  const GameHeader({
    super.key,
    required this.titulo,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.refresh, color: MesaColors.doradoClaro),
            onPressed: () => _confirmar(context),
          ),
        ],
      ),
    );
  }

  void _confirmar(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar partida?'),
        content: const Text('Se perderán los puntos actuales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onReiniciar();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}
