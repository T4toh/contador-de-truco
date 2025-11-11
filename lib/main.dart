import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ContadorDeTrucoApp());
}

class ContadorDeTrucoApp extends StatelessWidget {
  const ContadorDeTrucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador de Truco',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.ralewayTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.ralewayTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system,
      home: const TrucoCounter(),
    );
  }
}

class TrucoCounter extends StatefulWidget {
  const TrucoCounter({super.key});

  @override
  State<TrucoCounter> createState() => _TrucoCounterState();
}

class _TrucoCounterState extends State<TrucoCounter> with TickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scoreA = prefs.getInt('scoreA') ?? 0;
      _scoreB = prefs.getInt('scoreB') ?? 0;
      _maxScore = prefs.getInt('maxScore') ?? 30;
      _teamAName = prefs.getString('teamAName') ?? 'Nosotros';
      _teamBName = prefs.getString('teamBName') ?? 'Ellos';
      _gameStarted = prefs.getBool('gameStarted') ?? false;
    });
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scoreA', _scoreA);
    await prefs.setInt('scoreB', _scoreB);
    await prefs.setInt('maxScore', _maxScore);
    await prefs.setString('teamAName', _teamAName);
    await prefs.setString('teamBName', _teamBName);
    await prefs.setBool('gameStarted', _gameStarted);
  }

  void _addPoints(String team, int points) {
    if (_gameFinished) return;
    
    setState(() {
      if (team == 'A') {
        int oldScore = _scoreA;
        _scoreA = (_scoreA + points).clamp(0, _maxScore);
        if (oldScore < 15 && _scoreA >= 15 && _maxScore == 30) {
          _animationController.forward().then((_) => _animationController.reverse());
        }
      } else {
        int oldScore = _scoreB;
        _scoreB = (_scoreB + points).clamp(0, _maxScore);
        if (oldScore < 15 && _scoreB >= 15 && _maxScore == 30) {
          _animationController.forward().then((_) => _animationController.reverse());
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nombre del $team', style: GoogleFonts.raleway()),
        content: TextField(
          controller: controller,
          style: GoogleFonts.raleway(),
          decoration: InputDecoration(
            hintText: 'Ingresa el nombre',
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
      return Scaffold(
        body: Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
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
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
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
        ),
      );
    }

    return Scaffold(
      body: OrientationBuilder(
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
                              Expanded(child: _buildTeamSection('A', _teamAName, _scoreA, colorScheme)),
                              _buildDivider(colorScheme),
                              Expanded(child: _buildTeamSection('B', _teamBName, _scoreB, colorScheme)),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildTeamSection('A', _teamAName, _scoreA, colorScheme)),
                              _buildDivider(colorScheme),
                              Expanded(child: _buildTeamSection('B', _teamBName, _scoreB, colorScheme)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('¿Reiniciar partida?', style: GoogleFonts.raleway()),
                  content: Text('Se perderán los puntos actuales.', style: GoogleFonts.raleway()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar', style: GoogleFonts.raleway()),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _gameStarted = false;
                        });
                        _resetGame();
                      },
                      child: Text('Reiniciar', style: GoogleFonts.raleway()),
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

  Widget _buildTeamSection(String team, String name, int score, ColorScheme colorScheme) {
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
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
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: MatchstickCounter(points: score),
                ),
                Text(
                  '$score',
                  style: GoogleFonts.raleway(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: FilledButton.tonal(
                onPressed: _gameFinished ? null : () => _addPoints(team, -1),
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

class WinnerBottomSheet extends StatelessWidget {
  final String winnerName;
  final VoidCallback onReset;

  const WinnerBottomSheet({
    super.key,
    required this.winnerName,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 100),
          ),
          const SizedBox(height: 20),
          Text(
            '¡GANÓ $winnerName!',
            style: GoogleFonts.raleway(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Nueva Partida',
              style: GoogleFonts.raleway(fontSize: 18),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class MatchstickCounter extends StatelessWidget {
  final int points;

  const MatchstickCounter({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            '—',
            style: GoogleFonts.raleway(
              fontSize: 60,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      );
    }

    int fullGroups = points ~/ 5;
    int remainingSticks = points % 5;

    List<Widget> allGroups = [];

    for (int i = 0; i < fullGroups; i++) {
      allGroups.add(const MatchstickGroup(count: 5));
    }

    if (remainingSticks > 0) {
      allGroups.add(MatchstickGroup(count: remainingSticks));
    }

    // Agrupar en filas de 3
    List<Widget> rows = [];
    for (int i = 0; i < allGroups.length; i += 3) {
      int end = (i + 3 < allGroups.length) ? i + 3 : allGroups.length;
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allGroups.sublist(i, end).map((group) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: group,
            );
          }).toList(),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: row,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MatchstickGroup extends StatelessWidget {
  final int count;

  const MatchstickGroup({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: MatchstickGroupPainter(count: count),
      ),
    );
  }
}

class MatchstickGroupPainter extends CustomPainter {
  final int count;

  MatchstickGroupPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final woodPaint = Paint()
      ..color = Colors.brown[400]!
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()
      ..color = Colors.redAccent[700]!
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final boxSize = 35.0;

    if (count >= 1) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY - boxSize / 2,
          centerX - boxSize / 2, centerY + boxSize / 2);
    }

    if (count >= 2) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY - boxSize / 2,
          centerX + boxSize / 2, centerY - boxSize / 2);
    }

    if (count >= 3) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX + boxSize / 2, centerY - boxSize / 2,
          centerX + boxSize / 2, centerY + boxSize / 2);
    }

    if (count >= 4) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY + boxSize / 2,
          centerX + boxSize / 2, centerY + boxSize / 2);
    }

    if (count == 5) {
      _drawMatchstick(canvas, woodPaint, headPaint,
          centerX - boxSize / 2, centerY + boxSize / 2,
          centerX + boxSize / 2, centerY - boxSize / 2);
    }
  }

  void _drawMatchstick(Canvas canvas, Paint woodPaint, Paint headPaint,
      double x1, double y1, double x2, double y2) {
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), woodPaint);
    headPaint.strokeWidth = 6.5;
    canvas.drawCircle(Offset(x1, y1), 3.5, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
