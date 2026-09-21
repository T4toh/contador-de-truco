import 'package:flutter/material.dart';

import '../widgets/felt_background.dart';
import '../widgets/game_header.dart';
import '../widgets/name_dialog.dart';
import '../widgets/setup_choice.dart';
import '../widgets/winner_bottom_sheet.dart';
import 'generala_game.dart';
import 'generala_storage.dart';
import 'jugada_sheet.dart';
import 'planilla.dart';
import 'reglas.dart';

/// Planilla de Generala. Misma estructura que CounterScreen: setup mientras
/// `!empezada`, partida después, planilla de ganador al terminar.
class GeneralaScreen extends StatefulWidget {
  /// `versionName` instalado; se muestra chico en el setup.
  final String? version;

  const GeneralaScreen({super.key, this.version});

  @override
  State<GeneralaScreen> createState() => _GeneralaScreenState();
}

class _GeneralaScreenState extends State<GeneralaScreen> {
  final _storage = GeneralaStorage();
  GeneralaGame _juego = GeneralaGame.nueva();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final juego = await _storage.cargar();
    if (!mounted) return;
    setState(() => _juego = juego);
  }

  void _empezar(int participantes) {
    setState(() => _juego.empezar(participantes));
    _storage.guardar(_juego);
  }

  void _tocarCelda(int jugador, Casilla casilla) {
    if (_juego.terminada) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => JugadaSheet(
        casilla: casilla,
        jugador: _juego.nombres[jugador],
        tieneValor: _juego.valor(jugador, casilla) != null,
        onElegir: (jugada) => _anotar(jugador, casilla, jugada),
      ),
    );
  }

  void _anotar(int jugador, Casilla casilla, Jugada? jugada) {
    setState(() {
      if (jugada == null) {
        _juego.borrar(jugador, casilla);
      } else {
        _juego.anotar(jugador, casilla, jugada);
      }
    });
    _storage.guardar(_juego);
    if (_juego.terminada) _mostrarFin();
  }

  void _mostrarFin() {
    final nombres = _juego.ganadores.map((i) => _juego.nombres[i]).toList();
    final empate = nombres.length > 1;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => WinnerBottomSheet(
        winnerName: nombres.join(' y '),
        titulo: empate ? '¡EMPATE!\n${nombres.join(' y ')}' : null,
        onReset: () {
          Navigator.pop(context);
          _volverAlSetup();
        },
      ),
    );
  }

  void _volverAlSetup() {
    setState(() => _juego.reiniciar());
    _storage.guardar(_juego);
  }

  Future<void> _renombrar(int jugador) async {
    final nombre = await mostrarNameDialog(
      context,
      titulo: 'Nombre del jugador',
      actual: _juego.nombres[jugador],
    );
    if (nombre == null) return;
    setState(() => _juego.renombrar(jugador, nombre));
    _storage.guardar(_juego);
  }

  @override
  Widget build(BuildContext context) {
    if (!_juego.empezada) {
      return FeltBackground(
        child: SetupChoice(
          titulo: '¿Cuántos jugadores?',
          subtitulo: 'Puntaje según reglamento Ruibal',
          opciones: [for (var n = minJugadores; n <= maxJugadores; n++) n],
          etiqueta: (n) => '$n jugadores',
          alElegir: _empezar,
          version: widget.version,
        ),
      );
    }

    return FeltBackground(
      child: SafeArea(
        child: Column(
          children: [
            GameHeader(
              titulo: 'Vuelta ${_juego.vuelta} de ${Casilla.values.length}',
              onReiniciar: _volverAlSetup,
            ),
            Expanded(
              child: Planilla(
                juego: _juego,
                onCelda: _tocarCelda,
                onRenombrar: _renombrar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
