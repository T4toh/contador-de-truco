import 'package:flutter/material.dart';

import '../theme/mesa_colors.dart';
import '../widgets/felt_background.dart';
import '../widgets/game_header.dart';
import '../widgets/name_dialog.dart';
import '../widgets/score_panel.dart';
import '../widgets/winner_bottom_sheet.dart';
import 'game_spec.dart';
import 'game_storage.dart';
import 'panel_layout.dart';
import 'score_game.dart';

/// Única pantalla de contador. Lo que cambia entre juegos es el GameSpec.
class CounterScreen extends StatefulWidget {
  final GameSpec spec;

  const CounterScreen({super.key, required this.spec});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final _storage = GameStorage();
  late ScoreGame _juego = ScoreGame.nueva(widget.spec);

  /// Tope elegido mientras se completa el setup, antes de empezar.
  int? _topeElegido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final juego = await _storage.cargar(widget.spec);
    if (!mounted) return;
    setState(() => _juego = juego);
  }

  void _sumar(int indice, int puntos) {
    if (_juego.terminada) return;
    setState(() => _juego.sumar(indice, puntos));
    _storage.guardar(_juego);
    if (_juego.terminada) _mostrarGanador();
  }

  void _mostrarGanador() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => WinnerBottomSheet(
        winnerName: _juego.ganador ?? '',
        onReset: () {
          Navigator.pop(context);
          _volverAlSetup();
        },
      ),
    );
  }

  void _volverAlSetup() {
    setState(() {
      _juego.reiniciar();
      _juego.empezada = false;
      _topeElegido = null;
    });
    _storage.guardar(_juego);
  }

  Future<void> _renombrar(int indice) async {
    // "Equipo" solo para juegos de exactamente dos bandos fijos, como Truco.
    // Cualquier otro caso —elige cantidad, o tiene tres o más fijos— es "jugador".
    final nombre = await mostrarNameDialog(
      context,
      titulo: widget.spec.participantes.first > 2 || widget.spec.eligeParticipantes
          ? 'Nombre del jugador'
          : 'Nombre del equipo',
      actual: _juego.nombres[indice],
    );
    if (nombre == null) return;
    setState(() => _juego.renombrar(indice, nombre));
    _storage.guardar(_juego);
  }

  void _empezar({required int tope, required int participantes}) {
    setState(() => _juego.empezar(tope: tope, participantes: participantes));
    _storage.guardar(_juego);
  }

  @override
  Widget build(BuildContext context) {
    if (!_juego.empezada) return FeltBackground(child: _setup());

    return FeltBackground(
      child: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientacion) => Column(
            children: [
              GameHeader(
                titulo: _tituloPartida(),
                onReiniciar: _volverAlSetup,
              ),
              Expanded(child: _tablero(orientacion)),
            ],
          ),
        ),
      ),
    );
  }

  String _tituloPartida() =>
      widget.spec.eligeTope ? 'Partida a ${_juego.tope}' : widget.spec.titulo;

  Widget _tablero(Orientation orientacion) {
    final filas = layoutFor(_juego.participantes, orientacion);
    return Column(
      children: filas
          .map((fila) => Expanded(
                child: Row(
                  children: fila
                      .map((i) => Expanded(child: _panel(i)))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _panel(int indice) {
    final hito = widget.spec.hito;
    final muestra = _juego.muestraHito && hito != null;
    final cruzo = _juego.cruzoElHito(indice);

    return ScorePanel(
      nombre: _juego.nombres[indice],
      puntaje: _juego.puntajes[indice],
      chip: muestra ? (cruzo ? hito.despues : hito.antes) : null,
      chipActivo: cruzo,
      onSumar: () => _sumar(indice, 1),
      onRestar: _juego.terminada ? null : () => _sumar(indice, -1),
      onRenombrar: () => _renombrar(indice),
    );
  }

  // ---- setup ----

  Widget _setup() {
    // Primero el tope, después los participantes. Ese orden importa: es el
    // que dejan fijo los tests de widget.
    if (widget.spec.eligeTope && _topeElegido == null) {
      return _elegir(
        titulo: null,
        opciones: widget.spec.topes,
        etiqueta: widget.spec.etiquetaTope,
        alElegir: (tope) {
          if (widget.spec.eligeParticipantes) {
            setState(() => _topeElegido = tope);
          } else {
            _empezar(tope: tope, participantes: widget.spec.participantes.first);
          }
        },
      );
    }

    if (widget.spec.eligeParticipantes) {
      return _elegir(
        titulo: '¿Cuántos jugadores?',
        opciones: widget.spec.participantes,
        etiqueta: (n) => '$n jugadores',
        alElegir: (n) => _empezar(
          tope: _topeElegido ?? widget.spec.topes.first,
          participantes: n,
        ),
      );
    }

    // Nada que preguntar.
    return _elegir(
      titulo: null,
      opciones: const [0],
      etiqueta: (_) => 'Empezar',
      alElegir: (_) => _empezar(
        tope: widget.spec.topes.first,
        participantes: widget.spec.participantes.first,
      ),
    );
  }

  Widget _elegir({
    required String? titulo,
    required List<int> opciones,
    required String Function(int) etiqueta,
    required void Function(int) alElegir,
  }) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (titulo != null) ...[
                Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
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
                    child: Text(
                      etiqueta(o),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
