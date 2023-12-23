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
    obstacleTimer = Timer(1, onTick: addObstacle, repeat: true);
    obstacleTimer.start();
  }

  void addObstacle() {
    // 새 장애물 생성 및 추가
    var obstacle = Obstacle(
      position: Vector2(size.x, size.y - 60),
      screenHeight: size.y,
    );
    add(obstacle);

    // 타이머 재설정
    double randomInterval = Random().nextDouble() * 4 + 2; // 1초에서 3초 사이
    obstacleTimer.stop();
    obstacleTimer = Timer(randomInterval, onTick: addObstacle, repeat: true);
    obstacleTimer.start();
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.jump();
  }

  @override
  void update(double dt) {
    super.update(dt);
    obstacleTimer.update(dt);
  }
}

class Player extends RectangleComponent {
  static const double playerSize = 50;
  static const double jumpSpeed = -500; // 점프 속도를 좀 더 높게 설정
  double verticalSpeed = 0;
  double gravity = 800; // 중력 값을 적절하게 조정
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
        // 바닥에 도달했는지 확인
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
    screenWidth = gameRef.size.x; // 게임 화면의 너비를 저장
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 오른쪽에서 왼쪽으로 이동
    x -= speed * dt;

    // 화면 왼쪽 끝에 도달하면 위치 초기화
    if (x + size.x < 0) {
      x = screenWidth; // 저장된 게임 화면의 너비를 사용하여 재설정
    }
  }
}
