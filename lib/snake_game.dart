import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SnakeGame extends StatefulWidget {
  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 20;
  static const double initialSpeed = 200.0;

  double cellSize = 20.0; // Adjust the initial size as needed
  late double snakeSpeed;

  List<Offset> snake = [Offset(5, 5)];
  Offset food = Offset(10, 10);
  Direction direction = Direction.right;
  Timer? timer;
  int score = 0;
  bool isGameRunning = false;

  @override
  void initState() {
    super.initState();
    snakeSpeed = initialSpeed;
  }

  void startGame() {
    if (!isGameRunning) {
      setState(() {
        isGameRunning = true;
        snake = [Offset(5, 5)];
        direction = Direction.right;
        score = 0;
        snakeSpeed = initialSpeed;
        generateFood();
        timer = Timer.periodic(Duration(milliseconds: snakeSpeed.toInt()),
            (Timer t) {
          moveSnake();
          checkCollision();
        });
      });
    }
  }

  void generateFood() {
    final Random rand = Random();
    Offset newFood;

    do {
      newFood = Offset(
        rand.nextInt(gridSize).toDouble(),
        rand.nextInt(gridSize).toDouble(),
      );
    } while (snake.contains(newFood));

    food = newFood;
  }

  void moveSnake() {
    setState(() {
      switch (direction) {
        case Direction.up:
          snake.insert(0, Offset(snake.first.dx, snake.first.dy - 1));
          break;
        case Direction.down:
          snake.insert(0, Offset(snake.first.dx, snake.first.dy + 1));
          break;
        case Direction.left:
          snake.insert(0, Offset(snake.first.dx - 1, snake.first.dy));
          break;
        case Direction.right:
          snake.insert(0, Offset(snake.first.dx + 1, snake.first.dy));
          break;
      }

      if (snake.first == food) {
        generateFood();
        score++;
        snakeSpeed *=
            0.95; // Make the game slightly faster with each food eaten
        timer?.cancel();
        timer = Timer.periodic(Duration(milliseconds: snakeSpeed.toInt()),
            (Timer t) {
          moveSnake();
          checkCollision();
        });
      } else {
        snake.removeLast();
      }
    });
  }

  void checkCollision() {
    if (snake.first.dx < 0 ||
        snake.first.dx >= gridSize ||
        snake.first.dy < 0 ||
        snake.first.dy >= gridSize ||
        snake.sublist(1).contains(snake.first)) {
      // Game Over
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Game Over'),
            content: Text('Your score: $score'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  stopGame();
                },
                child: Text('Play Again'),
              ),
            ],
          );
        },
      );
      stopGame();
    }
  }

  void stopGame() {
    setState(() {
      isGameRunning = false;
      timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    cellSize = screenWidth / gridSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 235, 235, 235),
        centerTitle: true,
        title: Text(
          'Snakeee',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Text(
              'Score: $score',
              style:
                  TextStyle(fontSize: screenWidth * 0.04, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromARGB(255, 13, 58, 19),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 0 &&
                          direction != Direction.up) {
                        direction = Direction.down;
                      } else if (details.primaryDelta! < 0 &&
                          direction != Direction.down) {
                        direction = Direction.up;
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      if (details.primaryDelta! > 0 &&
                          direction != Direction.left) {
                        direction = Direction.right;
                      } else if (details.primaryDelta! < 0 &&
                          direction != Direction.right) {
                        direction = Direction.left;
                      }
                    },
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: BoundaryPainter(gridSize, cellSize),
                          size:
                              Size(constraints.maxWidth, constraints.maxWidth),
                        ),
                        CustomPaint(
                          painter:
                              SnakePainter(snake, food, gridSize, cellSize),
                          size:
                              Size(constraints.maxWidth, constraints.maxWidth),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: screenWidth * 0.1),
            child: ElevatedButton(
              onPressed: startGame,
              child: Text(
                'Start',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int gridSize;
  final double cellSize;

  SnakePainter(this.snake, this.food, this.gridSize, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint snakePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.green, Colors.lightGreen],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(Offset.zero, Offset(cellSize, cellSize)));

    final Paint foodPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red, Colors.orange],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(Offset.zero, Offset(cellSize, cellSize)));

    // Draw snake
    for (Offset position in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(position.dx * cellSize, position.dy * cellSize),
            Offset((position.dx + 1) * cellSize, (position.dy + 1) * cellSize),
          ),
          Radius.circular(cellSize / 2),
        ),
        snakePaint,
      );
    }

    // Draw food
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(food.dx * cellSize, food.dy * cellSize),
          Offset((food.dx + 1) * cellSize, (food.dy + 1) * cellSize),
        ),
        Radius.circular(cellSize / 2),
      ),
      foodPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class BoundaryPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;

  BoundaryPainter(this.gridSize, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boundaryPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw rounded squares for boundaries
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromPoints(
              Offset(i * cellSize, j * cellSize),
              Offset((i + 1) * cellSize, (j + 1) * cellSize),
            ),
            Radius.circular(cellSize / 4),
          ),
          boundaryPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

enum Direction { up, down, left, right }
