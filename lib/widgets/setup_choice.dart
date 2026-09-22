import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Pantalla de setup: título opcional y una columna de botones grandes, uno
/// por opción. La usan CounterScreen y GeneralaScreen.
class SetupChoice extends StatelessWidget {
  final String? titulo;

  /// Línea chica debajo del título. Generala la usa para citar el reglamento.
  final String? subtitulo;
  final List<int> opciones;
  final String Function(int) etiqueta;
  final void Function(int) alElegir;

  /// `versionName` instalado; null no dibuja nada.
  final String? version;

  const SetupChoice({
    super.key,
    this.titulo,
    this.subtitulo,
    required this.opciones,
    required this.etiqueta,
    required this.alElegir,
    this.version,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final version = this.version;
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (titulo != null) ...[
                    Text(titulo!, style: textos.headlineMedium),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitulo!,
                        style: textos.bodySmall?.copyWith(
                          color: MesaColors.crema.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                  ...opciones.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: FilledButton.tonal(
                        onPressed: () => alElegir(o),
                        style: FilledButton.styleFrom(
                          backgroundColor: MesaColors.maderaClara,
                          foregroundColor: MesaColors.crema,
                          minimumSize: const Size(360, 0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: MesaColors.dorado),
                          ),
                        ),
                        child: Text(etiqueta(o), style: textos.headlineMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Solo en el setup: jugando no molesta.
          if (version != null)
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                'v$version',
                style: textos.bodySmall?.copyWith(
                  color: MesaColors.crema.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
