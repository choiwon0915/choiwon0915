import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class _Food {
  _Food(this.position, this.size);

  final Offset position;
  final int size;

  double get radius => 5 + size * 2.5;
}

class _Enemy {
  _Enemy(this.position, this.direction, this.size, this.speed);

  Offset position;
  Offset direction;
  final int size;
  final double speed;

  double get radius => 8 + size * 2.5;
}

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SnakeGamePage(),
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  static const double worldSize = 2000;
  static const double boardSize = 720;
  static const double moveSpeed = 205;
  static const int largestFoodSize = 5;
  static const int minimumEnemies = 10;
  static const int nearbySmallFoodCount = 120;

  final List<Offset> _snake = [];
  final List<_Food> _foods = [];
  final List<_Enemy> _enemies = [];
  Offset _pointer = const Offset(360, 360);
  Offset _camera = Offset.zero;
  Offset _direction = const Offset(1, 0);
  bool _isPointerDown = false;
  bool _isStarted = false;
  bool _isGameOver = false;
  int _score = 0;
  int _growth = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _resetGame();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_isStarted && !_isGameOver) {
        setState(_updateGame);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _resetGame() {
    _snake
      ..clear()
      ..addAll([
        const Offset(900, 900),
        const Offset(880, 900),
        const Offset(860, 900),
        const Offset(840, 900),
        const Offset(820, 900),
        const Offset(800, 900),
      ]);

    _foods.clear();
    _enemies.clear();
    _spawnFoods();
    _spawnEnemies();
    _pointer = const Offset(boardSize / 2, boardSize / 2);
    _direction = const Offset(1, 0);
    _camera = Offset(
      (_snake.first.dx - boardSize / 2).clamp(0, worldSize - boardSize),
      (_snake.first.dy - boardSize / 2).clamp(0, worldSize - boardSize),
    );
    _score = 0;
    _growth = 0;
    _isStarted = false;
    _isGameOver = false;
    _isPointerDown = false;
  }

  void _spawnFoods() {
    final random = Random();
    final center = _snake.first;

    for (int index = 0; index < nearbySmallFoodCount; index++) {
      _foods.add(_Food(_randomPosition(center: center, spread: 500), 1));
    }

    for (int size = 2; size <= largestFoodSize; size++) {
      _foods.add(_Food(_randomPosition(), size));
    }
  }

  void _spawnEnemies() {
    while (_enemies.length < minimumEnemies) {
      final random = Random();
      _enemies.add(
        _Enemy(
          _randomPosition(center: _snake.first, spread: 850),
          _normalize(Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1)),
          2 + random.nextInt(3),
          45 + random.nextDouble() * 45,
        ),
      );
    }
  }

  Offset _randomPosition({Offset? center, double spread = 0}) {
    final random = Random();
    final origin = center ?? const Offset(worldSize / 2, worldSize / 2);

    for (int attempt = 0; attempt < 30; attempt++) {
      final candidate = spread == 0
          ? Offset(
              random.nextDouble() * (worldSize - 120) + 60,
              random.nextDouble() * (worldSize - 120) + 60,
            )
          : Offset(
              origin.dx + (random.nextDouble() * 2 - 1) * spread,
              origin.dy + (random.nextDouble() * 2 - 1) * spread,
            );

      if (candidate.dx >= 60 &&
          candidate.dx <= worldSize - 60 &&
          candidate.dy >= 60 &&
          candidate.dy <= worldSize - 60 &&
          !_snake.any((segment) => (segment - candidate).distance < 45)) {
        return candidate;
      }
    }

    return Offset(
      origin.dx.clamp(60.0, worldSize - 60).toDouble(),
      origin.dy.clamp(60.0, worldSize - 60).toDouble(),
    );
  }

  Offset _normalize(Offset value) {
    final length = value.distance;
    if (length < 0.0001) {
      return const Offset(0, 0);
    }
    return Offset(value.dx / length, value.dy / length);
  }

  Offset _clampPointer(Offset value) {
    return Offset(
      value.dx.clamp(0.0, boardSize).toDouble(),
      value.dy.clamp(0.0, boardSize).toDouble(),
    );
  }

  double _angleDifference(double target, double current) {
    var diff = target - current;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    return diff;
  }

  void _updateEnemies() {
    final random = Random();
    final deadEnemies = <_Enemy>[];

    for (final enemy in _enemies) {
      final turn = Offset(
        (random.nextDouble() - 0.5) * 0.12,
        (random.nextDouble() - 0.5) * 0.12,
      );
      enemy.direction = _normalize(enemy.direction + turn);
      var nextPosition = enemy.position + enemy.direction * (enemy.speed / 60);

      if (nextPosition.dx < 30 || nextPosition.dx > worldSize - 30) {
        enemy.direction = Offset(-enemy.direction.dx, enemy.direction.dy);
        nextPosition = enemy.position + enemy.direction * (enemy.speed / 60);
      }
      if (nextPosition.dy < 30 || nextPosition.dy > worldSize - 30) {
        enemy.direction = Offset(enemy.direction.dx, -enemy.direction.dy);
        nextPosition = enemy.position + enemy.direction * (enemy.speed / 60);
      }

      enemy.position = nextPosition;
      if ((enemy.position - _snake.first).distance < enemy.radius + 12) {
        deadEnemies.add(enemy);
      }
    }

    for (final enemy in deadEnemies) {
      _convertEnemyToFood(enemy);
      _enemies.remove(enemy);
      _score += enemy.size * 15;
    }
    _spawnEnemies();
  }

  void _convertEnemyToFood(_Enemy enemy) {
    final random = Random();
    final foodCount = enemy.size * 4;

    for (int index = 0; index < foodCount; index++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * 35;
      final position = enemy.position + Offset(cos(angle), sin(angle)) * distance;
      _foods.add(
        _Food(
          Offset(
            position.dx.clamp(20.0, worldSize - 20).toDouble(),
            position.dy.clamp(20.0, worldSize - 20).toDouble(),
          ),
          1 + random.nextInt(enemy.size),
        ),
      );
    }
  }

  void _updateGame() {
    _updateEnemies();
    final head = _snake.first;
    final worldPointer = _pointer + _camera;
    final targetVector = worldPointer - head;

    if (targetVector.distance > 1) {
      final desired = _normalize(targetVector);
      final current = _normalize(_direction);
      final desiredAngle = atan2(desired.dy, desired.dx);
      final currentAngle = atan2(current.dy, current.dx);
      final delta = _angleDifference(desiredAngle, currentAngle);
      final rotation = delta.clamp(-0.18, 0.18);
      final nextAngle = currentAngle + rotation;
      _direction = Offset(cos(nextAngle), sin(nextAngle));
    }

    final nextHead = head + _direction * (moveSpeed / 60);

    if (nextHead.dx < 18 ||
        nextHead.dx > worldSize - 18 ||
        nextHead.dy < 18 ||
        nextHead.dy > worldSize - 18) {
      _isGameOver = true;
      return;
    }

    _snake.insert(0, nextHead);

    final foodIndex = _foods.indexWhere(
      (food) => (nextHead - food.position).distance < food.radius + 12,
    );
    if (foodIndex >= 0) {
      final food = _foods.removeAt(foodIndex);
      _score += food.size * 10;
      _growth += food.size;
    }

    if (_growth > 0) {
      _growth--;
    } else {
      _snake.removeLast();
      if (_isPointerDown && _snake.length > 6) {
        _snake.removeLast();
      }
    }

    _camera = Offset(
      (nextHead.dx - boardSize / 2).clamp(0, worldSize - boardSize),
      (nextHead.dy - boardSize / 2).clamp(0, worldSize - boardSize),
    );
  }

  void _restartGame() {
    setState(_resetGame);
  }

  void _startGame() {
    setState(() {
      _isStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final worldChildren = <Widget>[];
    final viewportRect = Rect.fromLTWH(0, 0, boardSize, boardSize);

    for (double x = 0; x < worldSize; x += 40) {
      for (double y = 0; y < worldSize; y += 40) {
        final worldPoint = Offset(x, y);
        final screenPoint = worldPoint - _camera;
        if (!viewportRect.contains(screenPoint)) {
          continue;
        }

        worldChildren.add(
          Positioned(
            left: screenPoint.dx,
            top: screenPoint.dy,
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withAlpha((0.04 * 255).round()),
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      }
    }

    for (final food in _foods) {
      final foodScreen = food.position - _camera;
      final radius = food.radius;
      final color = food.size == largestFoodSize
          ? Colors.redAccent
          : Color.lerp(Colors.limeAccent, Colors.orangeAccent,
                  food.size / largestFoodSize) ?? Colors.limeAccent;
      worldChildren.add(
        Positioned(
          left: foodScreen.dx - radius,
          top: foodScreen.dy - radius,
          width: radius * 2,
          height: radius * 2,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: food.size == largestFoodSize ? 10 : 3,
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final enemy in _enemies) {
      final enemyScreen = enemy.position - _camera;
      final radius = enemy.radius;
      worldChildren.add(
        Positioned(
          left: enemyScreen.dx - radius,
          top: enemyScreen.dy - radius,
          width: radius * 2,
          height: radius * 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.yellowAccent, width: 2),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < _snake.length; i++) {
      final segmentScreen = _snake[i] - _camera;
      worldChildren.add(
        Positioned(
          left: segmentScreen.dx - 12,
          top: segmentScreen.dy - 12,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: i == 0 ? Colors.greenAccent : Colors.lightGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    final pointerScreen = _pointer;
    worldChildren.add(
      Positioned(
        left: pointerScreen.dx - 7,
        top: pointerScreen.dy - 7,
        width: 14,
        height: 14,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    if (!_isStarted || _isGameOver) {
      worldChildren.add(
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha((0.45 * 255).round()),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isGameOver ? 'Game Over' : 'Snake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isGameOver ? _restartGame : _startGame,
                    child: Text(_isGameOver ? 'Restart' : 'Start Game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08120D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Snake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isPointerDown ? 'Shrinking while holding left mouse' : 'Follow the pointer to steer',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Listener(
                    onPointerMove: (event) {
                      _pointer = _clampPointer(event.localPosition);
                    },
                    onPointerDown: (_) {
                      _isPointerDown = true;
                    },
                    onPointerUp: (_) {
                      _isPointerDown = false;
                    },
                    onPointerCancel: (_) {
                      _isPointerDown = false;
                    },
                    child: Container(
                      width: boardSize,
                      height: boardSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1B12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: Stack(children: worldChildren),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
