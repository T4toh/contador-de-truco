import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/matchstick_counter.dart';
import '../widgets/winner_bottom_sheet.dart';

class TrucoCounter extends StatefulWidget {
  const TrucoCounter({super.key});

  @override
  State<TrucoCounter> createState() => _TrucoCounterState();
}

class _TrucoCounterState extends State<TrucoCounter>
    with TickerProviderStateMixin {
  int _scoreA = 0;
  int _scoreB = 0;
  int _maxScore = 30;
  String _teamAName = 'Nosotros';
  String _teamBName = 'Ellos';
  bool _gameStarted = false;
  bool _gameFinished = false;
  String _winner = '';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadGame();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate from old unprefixed keys if present
    if (prefs.containsKey('gameStarted') && !prefs.containsKey('truco_gameStarted')) {
      await prefs.setInt('truco_scoreA', prefs.getInt('scoreA') ?? 0);
      await prefs.setInt('truco_scoreB', prefs.getInt('scoreB') ?? 0);
      await prefs.setInt('truco_maxScore', prefs.getInt('maxScore') ?? 30);
      await prefs.setString('truco_teamAName', prefs.getString('teamAName') ?? 'Nosotros');
      await prefs.setString('truco_teamBName', prefs.getString('teamBName') ?? 'Ellos');
      await prefs.setBool('truco_gameStarted', prefs.getBool('gameStarted') ?? false);
      for (final key in ['scoreA', 'scoreB', 'maxScore', 'teamAName', 'teamBName', 'gameStarted']) {
        await prefs.remove(key);
      }
    }
    setState(() {
      _scoreA = prefs.getInt('truco_scoreA') ?? 0;
      _scoreB = prefs.getInt('truco_scoreB') ?? 0;
      _maxScore = prefs.getInt('truco_maxScore') ?? 30;
      _teamAName = prefs.getString('truco_teamAName') ?? 'Nosotros';
      _teamBName = prefs.getString('truco_teamBName') ?? 'Ellos';
      _gameStarted = prefs.getBool('truco_gameStarted') ?? false;
    });
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('truco_scoreA', _scoreA);
    await prefs.setInt('truco_scoreB', _scoreB);
    await prefs.setInt('truco_maxScore', _maxScore);
    await prefs.setString('truco_teamAName', _teamAName);
    await prefs.setString('truco_teamBName', _teamBName);
    await prefs.setBool('truco_gameStarted', _gameStarted);
  }

  void _addPoints(String team, int points) {
    if (_gameFinished) return;

    setState(() {
      if (team == 'A') {
        int oldScore = _scoreA;
        _scoreA = (_scoreA + points).clamp(0, _maxScore);
        if (oldScore < 15 && _scoreA >= 15 && _maxScore == 30) {
          _animationController
              .forward()
              .then((_) => _animationController.reverse());
        }
      } else {
        int oldScore = _scoreB;
        _scoreB = (_scoreB + points).clamp(0, _maxScore);
        if (oldScore < 15 && _scoreB >= 15 && _maxScore == 30) {
          _animationController
              .forward()
              .then((_) => _animationController.reverse());
        }
      }

      if (_scoreA >= _maxScore) {
        _gameFinished = true;
        _winner = _teamAName;
        _showWinnerDialog();
      } else if (_scoreB >= _maxScore) {
        _gameFinished = true;
        _winner = _teamBName;
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

  void _resetGame() {
    setState(() {
      _scoreA = 0;
      _scoreB = 0;
      _gameFinished = false;
      _winner = '';
    });
    _saveGame();
  }

  void _startNewGame(int maxScore) {
    setState(() {
      _maxScore = maxScore;
      _scoreA = 0;
      _scoreB = 0;
      _gameStarted = true;
      _gameFinished = false;
      _winner = '';
    });
    _saveGame();
  }

  void _showTeamNameDialog(String team) async {
    final controller = TextEditingController(
      text: team == 'A' ? _teamAName : _teamBName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nombre del equipo', style: GoogleFonts.raleway()),
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
        if (team == 'A') {
          _teamAName = result;
        } else {
          _teamBName = result;
        }
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
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
                colorScheme.tertiaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(colorScheme),
                Expanded(
                  child: orientation == Orientation.portrait
                      ? Column(
                          children: [
                            Expanded(
                                child: _buildTeamSection(
                                    'A', _teamAName, _scoreA, colorScheme)),
                            _buildDivider(colorScheme),
                            Expanded(
                                child: _buildTeamSection(
                                    'B', _teamBName, _scoreB, colorScheme)),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                                child: _buildTeamSection(
                                    'A', _teamAName, _scoreA, colorScheme)),
                            _buildDivider(colorScheme),
                            Expanded(
                                child: _buildTeamSection(
                                    'B', _teamBName, _scoreB, colorScheme)),
                          ],
                        ),
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
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: () => _startNewGame(15),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 80, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'A MALAS',
                  style: GoogleFonts.raleway(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => _startNewGame(30),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 80, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'A BUENAS',
                  style: GoogleFonts.raleway(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
            'Partida a $_maxScore',
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

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 3,
      width: 3,
      color: colorScheme.primary,
    );
  }

  Widget _buildTeamSection(
      String team, String name, int score, ColorScheme colorScheme) {
    bool enLasBuenas = _maxScore == 30 && score >= 15;
    Color backgroundColor = enLasBuenas
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: () => _addPoints(team, 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: backgroundColor,
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
                    onLongPress: () => _showTeamNameDialog(team),
                    child: Text(
                      name,
                      style: GoogleFonts.raleway(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (_maxScore == 30)
                  Chip(
                    label: Text(
                      enLasBuenas ? 'EN LAS BUENAS' : 'EN LAS MALAS',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: enLasBuenas
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: enLasBuenas
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                Expanded(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: MatchstickCounter(points: score),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$score',
                    style: GoogleFonts.raleway(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: FilledButton.tonal(
                onPressed:
                    _gameFinished ? null : () => _addPoints(team, -1),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
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
