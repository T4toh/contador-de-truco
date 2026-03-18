import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/matchstick_counter.dart';
import '../widgets/winner_bottom_sheet.dart';

class EscobaCounter extends StatefulWidget {
  const EscobaCounter({super.key});

  @override
  State<EscobaCounter> createState() => _EscobaCounterState();
}

class _EscobaCounterState extends State<EscobaCounter> {
  static const int _maxScore = 15;

  int _playerCount = 2;
  bool _gameStarted = false;
  bool _gameFinished = false;
  List<int> _scores = [];
  List<String> _playerNames = [];
  String _winner = '';

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('escoba_playerCount') ?? 2;
    final savedStarted = prefs.getBool('escoba_gameStarted') ?? false;

    final scores = List.generate(
      savedCount,
      (i) => prefs.getInt('escoba_score_$i') ?? 0,
    );
    final names = List.generate(
      savedCount,
      (i) => prefs.getString('escoba_name_$i') ?? _defaultName(i),
    );

    setState(() {
      _playerCount = savedCount;
      _gameStarted = savedStarted;
      _scores = scores;
      _playerNames = names;
    });
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('escoba_playerCount', _playerCount);
    await prefs.setBool('escoba_gameStarted', _gameStarted);
    for (int i = 0; i < _playerCount; i++) {
      await prefs.setInt('escoba_score_$i', _scores[i]);
      await prefs.setString('escoba_name_$i', _playerNames[i]);
    }
  }

  String _defaultName(int index) {
    const names = ['Jugador 1', 'Jugador 2', 'Jugador 3', 'Jugador 4'];
    return names[index];
  }

  void _startNewGame(int playerCount) {
    setState(() {
      _playerCount = playerCount;
      _scores = List.filled(playerCount, 0);
      _playerNames = List.generate(playerCount, _defaultName);
      _gameStarted = true;
      _gameFinished = false;
      _winner = '';
    });
    _saveGame();
  }

  void _resetGame() {
    setState(() {
      _scores = List.filled(_playerCount, 0);
      _gameFinished = false;
      _winner = '';
    });
    _saveGame();
  }

  void _addPoints(int playerIndex, int points) {
    if (_gameFinished) return;

    setState(() {
      _scores[playerIndex] =
          (_scores[playerIndex] + points).clamp(0, _maxScore);

      if (_scores[playerIndex] >= _maxScore) {
        _gameFinished = true;
        _winner = _playerNames[playerIndex];
        _showWinnerDialog();
      }
    });
    _saveGame();
  }

  void _showWinnerDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => WinnerBottomSheet(
        winnerName: _winner,
        onReset: () {
          Navigator.pop(context);
          setState(() {
            _gameStarted = false;
          });
          _resetGame();
        },
      ),
    );
  }

  void _showPlayerNameDialog(int playerIndex) async {
    final controller =
        TextEditingController(text: _playerNames[playerIndex]);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nombre del jugador', style: GoogleFonts.raleway()),
        content: TextField(
          controller: controller,
          style: GoogleFonts.raleway(),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ingresá el nombre',
            hintStyle: GoogleFonts.raleway(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.raleway()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Guardar', style: GoogleFonts.raleway()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _playerNames[playerIndex] = result;
      });
      _saveGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_gameStarted) {
      return _buildSetupView(colorScheme);
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.tertiaryContainer,
                colorScheme.secondaryContainer,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(colorScheme),
                Expanded(
                  child: _buildPlayersView(colorScheme, orientation),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetupView(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Cuántos jugadores?',
                style: GoogleFonts.raleway(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ...[2, 3, 4].map(
                (count) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: FilledButton.tonal(
                    onPressed: () => _startNewGame(count),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      '$count jugadores',
                      style: GoogleFonts.raleway(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Escoba del 15',
            style: GoogleFonts.raleway(
              fontSize: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton.filled(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('¿Reiniciar partida?',
                      style: GoogleFonts.raleway()),
                  content: Text('Se perderán los puntos actuales.',
                      style: GoogleFonts.raleway()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text('Cancelar', style: GoogleFonts.raleway()),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _gameStarted = false;
                        });
                        _resetGame();
                      },
                      child:
                          Text('Reiniciar', style: GoogleFonts.raleway()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersView(
      ColorScheme colorScheme, Orientation orientation) {
    if (_playerCount == 4) {
      // 2x2 grid regardless of orientation
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _buildPlayerPanel(0, colorScheme)),
                Expanded(
                    child: _buildPlayerPanel(1, colorScheme)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _buildPlayerPanel(2, colorScheme)),
                Expanded(
                    child: _buildPlayerPanel(3, colorScheme)),
              ],
            ),
          ),
        ],
      );
    }

    if (_playerCount == 3) {
      return orientation == Orientation.portrait
          ? Column(
              children: List.generate(
                3,
                (i) => Expanded(child: _buildPlayerPanel(i, colorScheme)),
              ),
            )
          : Row(
              children: List.generate(
                3,
                (i) => Expanded(child: _buildPlayerPanel(i, colorScheme)),
              ),
            );
    }

    // 2 players
    return orientation == Orientation.portrait
        ? Column(
            children: [
              Expanded(child: _buildPlayerPanel(0, colorScheme)),
              Expanded(child: _buildPlayerPanel(1, colorScheme)),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildPlayerPanel(0, colorScheme)),
              Expanded(child: _buildPlayerPanel(1, colorScheme)),
            ],
          );
  }

  Widget _buildPlayerPanel(int index, ColorScheme colorScheme) {
    final score = _scores[index];
    final name = _playerNames[index];

    return GestureDetector(
      onTap: () => _addPoints(index, 1),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        margin: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onLongPress: () => _showPlayerNameDialog(index),
                    child: Text(
                      name,
                      style: GoogleFonts.raleway(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Expanded(
                  child: MatchstickCounter(points: score),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '$score',
                    style: GoogleFonts.raleway(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: FilledButton.tonal(
                onPressed:
                    _gameFinished ? null : () => _addPoints(index, -1),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('-'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
