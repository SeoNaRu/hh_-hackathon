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

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 플레이어 추가
    player = Player(
      position: Vector2(size.x * 0.07, size.y - 60),
    );
    add(player);

    // 바닥 추가
    var floor = RectangleComponent(
      position: Vector2(0, size.y - 60),
      size: Vector2(size.x, 60),
      paint: Paint()..color = Colors.white,
    );
    add(floor);
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.jump();
  }
}

class Player extends RectangleComponent {
  static const double playerSize = 50;
  static const double jumpSpeed = -300; // 점프 속도
  double verticalSpeed = 10; // 현재 수직 속도
  double gravity = 10;
  double groundPosition = 20;
  bool isJumping = false;

  Player({required position})
      : super(
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

      // 바닥에 도달했는지 확인
      if (y > groundPosition) {
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
