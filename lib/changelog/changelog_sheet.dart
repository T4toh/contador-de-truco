import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme/mesa_colors.dart';
import 'changelog.dart';

/// Abre el changelog empaquetado (`CHANGELOG.md`, declarado en pubspec) en
/// un bottom sheet. Lo llaman el setup, al tocar la versión, y HomeScreen
/// la primera vez que arranca una versión nueva.
Future<void> mostrarChangelog(BuildContext context) async {
  final markdown = await rootBundle.loadString('CHANGELOG.md');
  if (!context.mounted) return;
  final secciones = parsearChangelog(markdown);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChangelogSheet(secciones: secciones),
  );
}

class ChangelogSheet extends StatelessWidget {
  final List<SeccionChangelog> secciones;

  const ChangelogSheet({super.key, required this.secciones});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final alto = MediaQuery.sizeOf(context).height * 0.75;
    return Container(
      height: alto,
      decoration: const BoxDecoration(
        color: MesaColors.maderaOscura,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: MesaColors.dorado, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novedades', style: textos.headlineMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final s in secciones) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: Text(
                        s.titulo,
                        style: textos.titleMedium?.copyWith(
                          color: MesaColors.doradoClaro,
                        ),
                      ),
                    ),
                    for (final l in s.lineas)
                      if (l.esSubtitulo)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(l.texto, style: textos.labelLarge),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            '•  ${l.texto}',
                            style: textos.bodyMedium,
                          ),
                        ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
