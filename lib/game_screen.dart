import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(
        game: DinoGame(),
      ),
    );
  }
}

class DinoGame extends FlameGame with TapDetector {
  late Player player;
  late Timer obstacleTimer;
  double lastObstacleX = double.infinity; // 마지막 장애물의 X 위치
  static const double minObstacleSpacing = 300; // 장애물 간 최소 간격

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 플레이어 추가
    player = Player(
      position: Vector2(size.x * 0.07, size.y - 60),
      screenHeight: size.y,
    );
    add(player);

    // 바닥 추가
    var floor = RectangleComponent(
      position: Vector2(0, size.y - 60),
      size: Vector2(size.x, 60),
      paint: Paint()..color = Colors.white,
    );
    add(floor);

    // 장애물 타이머 설정
    obstacleTimer = Timer(1.5, onTick: addObstacle, repeat: true);
    obstacleTimer.start();
  }

  void addObstacle() {
    var obstacle = Obstacle(
      position: Vector2(size.x, size.y - 60),
      screenHeight: size.y,
    );

    add(obstacle);
    lastObstacleX = size.x;
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.jump();
  }

  @override
  void update(double dt) {
    super.update(dt);
    obstacleTimer.update(dt);

    // 플레이어와 장애물의 충돌 검사
    final obstacles = children.whereType<Obstacle>();
    for (var obstacle in obstacles) {
      if (player.toRect().overlaps(obstacle.toRect())) {
        onCollision();
        break;
      }
    }

    children.whereType<Obstacle>().toList().forEach((obstacle) {
      if (obstacle.x + obstacle.width < 0) {
        remove(obstacle);
      }
    });
  }

  void onCollision() {
    // 게임 종료 로직
    print('게임 종료');
    resetGame();
  }

  void resetGame() {
    // 플레이어 위치 재설정
    player.position = Vector2(size.x * 0.07, size.y - 60);
    player.verticalSpeed = 0;
    player.isJumping = false;

    // 모든 장애물 제거
    children.whereType<Obstacle>().toList().forEach(remove);

    // 타이머 재설정
    obstacleTimer.stop();
    obstacleTimer = Timer(1.5, onTick: addObstacle, repeat: true);
    obstacleTimer.start();
  }
}

class Player extends RectangleComponent {
  static const double playerSize = 50;
  static const double jumpSpeed = -440; // 점프 속도를 좀 더 높게 설정
  double verticalSpeed = 20;
  double gravity = 1000; // 중력 값을 적절하게 조정
  double groundPosition = 540; // 바닥 위치 적절하게 조정
  bool isJumping = false;

  Player({required Vector2 position, required double screenHeight})
      : groundPosition = screenHeight - 60, // 바닥 위치를 화면 높이에서 60만큼 빼서 설정
        super(
          position: position,
          size: Vector2.all(playerSize),
          anchor: Anchor.bottomCenter,
          paint: Paint()..color = Colors.yellow,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (isJumping) {
      verticalSpeed += gravity * dt; // 중력 적용
      y += verticalSpeed * dt; // 수직 위치 업데이트

      if (y >= groundPosition) {
        y = groundPosition;
        isJumping = false;
        verticalSpeed = 0;
      }
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      verticalSpeed = jumpSpeed;
    }
  }
}

class Obstacle extends RectangleComponent with HasGameRef<DinoGame> {
  static const double speed = 200; // 장애물 이동 속도
  late double screenWidth;

  Obstacle({required Vector2 position, required double screenHeight})
      : super(
            position: position,
            size: Vector2(30, 60),
            anchor: Anchor.bottomRight,
            paint: Paint()..color = Colors.blue);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    screenWidth = gameRef.size.x;
  }

  @override
  void update(double dt) {
    super.update(dt);

    x -= speed * dt;

    // 장애물이 화면 왼쪽 끝에 도달하면 제거
    if (x + width < 0) {
      removeFromParent();
    }
  }
}
