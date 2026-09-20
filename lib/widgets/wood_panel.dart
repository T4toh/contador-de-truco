import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';

/// Tabla de madera sobre el paño. `destacado` la ilumina — lo usa el hito.
///
/// Al pasar a destacado da un pulso corto: es el "pasa a las buenas" que
/// antes vivía como ScaleTransition dentro del contador de Truco.
class WoodPanel extends StatefulWidget {
  final Widget child;
  final bool destacado;
  final EdgeInsets margin;

  const WoodPanel({
    super.key,
    required this.child,
    this.destacado = false,
    this.margin = const EdgeInsets.all(8),
  });

  @override
  State<WoodPanel> createState() => _WoodPanelState();
}

class _WoodPanelState extends State<WoodPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _escala = Tween<double>(begin: 1, end: 1.04)
      .animate(CurvedAnimation(parent: _pulso, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(WoodPanel anterior) {
    super.didUpdateWidget(anterior);
    if (widget.destacado && !anterior.destacado) {
      _pulso.forward().then((_) => _pulso.reverse());
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: widget.margin,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.destacado
                ? const [MesaColors.maderaDestacada, MesaColors.maderaClara]
                : const [MesaColors.maderaClara, MesaColors.maderaOscura],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.destacado ? MesaColors.dorado : MesaColors.maderaBorde,
            width: widget.destacado ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: MesaColors.sombraPanel,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
