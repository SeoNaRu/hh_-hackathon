import 'dart:async';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late DinoGame _game; // 게임 인스턴스를 저장하기 위한 변수
  bool isGameRunning = false;

  @override
  void initState() {
    super.initState();
    _game = DinoGame(
        onGameOver: showGameOverModal,
        onGameReady: () {
          isGameRunning = true;
          _game.startGame();
        });
  }

  void startGame() {
    setState(() {
      isGameRunning = true;
      _game.startGame();
    });
  }

  void showGameOverModal() {
    if (!isGameRunning) return; // 이미 게임이 종료된 상태라면 아무 것도 하지 않음

    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 바깥을 눌러서 닫을 수 없게 함
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('게임 오버'),
          content: Text('점수: ${_game.scoreDisplay.score}'),
          actions: <Widget>[
            TextButton(
              child: Text('다시 시작하기'),
              onPressed: () {
                Navigator.of(context).pop(); // 모달 닫기
                _game.resetGame(); // 게임 리셋
                startGame(); // 게임 재시작
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(game: _game),
    );
  }
}

class DinoGame extends FlameGame with TapDetector {
  final Function onGameOver; // 게임 오버 콜백
  bool isGameRunning = false;
  final Function onGameReady; // 게임이 준비되었을 때 호출될 콜백
  late SpriteComponent background;
  late SpriteComponent floor;

  late Player player;
  late Timer obstacleTimer;
  late ScoreComponent scoreDisplay; // 스코어 디스플레이 인스턴스
  double lastObstacleX = double.infinity; // 마지막 장애물의 X 위치
  static const double minObstacleSpacing = 300; // 장애물 간 최소 간격

  DinoGame({required this.onGameOver, required this.onGameReady});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // final backgroundImage = await images.load('background.png');
    // background = SpriteComponent()
    //   ..sprite = Sprite(backgroundImage)
    //   ..size = size;
    // add(background);

    // 패럴랙스 컴포넌트를 만들기 위해 이미지들의 파일 경로를 사용합니다.
    final parallaxComponent = await loadParallaxComponent(
      [
        ParallaxImageData('parallax/plx-1.png'),
        ParallaxImageData('parallax/plx-2.png'),
        ParallaxImageData('parallax/plx-3.png'),
        ParallaxImageData('parallax/plx-4.png'),
        ParallaxImageData('parallax/plx-5.png'),
        ParallaxImageData('parallax/plx-6.png'),
      ],
      baseVelocity: Vector2(20, 0), // 기본 속도 설정
      velocityMultiplierDelta: Vector2(1.1, 0), // 속도 증가량 설정
    );

    // 생성된 패럴랙스 컴포넌트를 게임에 추가합니다.
    add(parallaxComponent);

    player = Player(
      position: Vector2(size.x * 0.07, size.y - 60),
      screenHeight: size.y,
    );
    add(player);

    // 바닥 추가

    // final floorimage = await images.load('background.png');
    // floor = SpriteComponent()
    //   ..sprite = Sprite(floorimage)
    //   ..position = Vector2(0, size.y - 60)
    //   ..size = size;

    // // var floor = RectangleComponent(
    // //   position: Vector2(0, size.y - 60),
    // //   size: Vector2(size.x, 60),
    // //   paint: Paint()..color = Colors.red,
    // // );
    // add(floor);

    // 장애물 타이머 설정
    obstacleTimer = Timer(1.5, onTick: addObstacle, repeat: true);
    obstacleTimer.start();

    // 스코어 디스플레이 컴포넌트를 생성하고 게임에 추가
    scoreDisplay = ScoreComponent();
    add(scoreDisplay);

    onGameReady();
  }

  // 패럴랙스 컴포넌트를 로드하는 함수를 정의합니다.
  Future<ParallaxComponent> loadParallaxComponent(
    List<ParallaxImageData> data, {
    required Vector2 baseVelocity,
    required Vector2 velocityMultiplierDelta,
  }) async {
    final parallax = await Parallax.load(
      data,
      baseVelocity: baseVelocity,
      velocityMultiplierDelta: velocityMultiplierDelta,
    );
    return ParallaxComponent(parallax: parallax);
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
  void update(double dt) {
    if (isGameRunning) {
      super.update(dt);
      obstacleTimer.update(dt);
      scoreDisplay.update(dt);
    }

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

  void startGame() {
    isGameRunning = true;
    scoreDisplay.resetScore(); // 스코어 리셋

    resetGame();
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (isGameRunning) {
      player.jump();
    }
  }

  void onCollision() {
    if (!isGameRunning) return;

    isGameRunning = false; // 게임 실행 상태를 false로 설정

    children.whereType<Obstacle>().forEach((obstacle) {
      remove(obstacle); // 모든 장애물 제거
    });

    onGameOver(); // 게임 오버 콜백 호출
  }

  void resetGame() {
    player.position = Vector2(size.x * 0.07, size.y - 60);
    player.verticalSpeed = 0;
    player.isJumping = false;
    player.canDoubleJump = true;

    children.whereType<Obstacle>().toList().forEach(remove);

    obstacleTimer = Timer(1.5, onTick: addObstacle, repeat: true);
    obstacleTimer.start();

    scoreDisplay.score = 0;
    scoreDisplay.text = 'Score: 0'; // 스코어 텍스트도 업데이트해야 합니다.
  }
}

class Player extends RectangleComponent with HasGameRef<DinoGame> {
  late final SpriteAnimationComponent animationComponent;

  static const double playerSize = 50;
  static const double jumpSpeed = -380; // 점프 속도를 좀 더 높게 설정
  double verticalSpeed = 1000;
  double gravity = 800; // 중력 값을 적절하게 조정
  double groundPosition = 540; // 바닥 위치 적절하게 조정
  bool isJumping = false;
  bool canDoubleJump = true; // 2단 점프 가능 여부를 추적하는 변수

  Player({required Vector2 position, required double screenHeight})
      : groundPosition = screenHeight - 60, // 바닥 위치를 화면 높이에서 60만큼 빼서 설정

        super(
            position: position,
            size: Vector2(28, 34),
            anchor: Anchor.bottomCenter,
            paint: Paint()..color = Colors.transparent);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = await gameRef.images.load('Run(32x32).png');
    final spriteAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 12,
        stepTime: 0.05,
        textureSize: Vector2.all(32),
      ),
    );

    animationComponent = SpriteAnimationComponent(
      animation: spriteAnimation,
      position: Vector2(-8, -5),
      size: Vector2.all(40),
    );

    add(animationComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isJumping) {
      verticalSpeed += gravity * dt;
      y += verticalSpeed * dt;

      if (y >= groundPosition) {
        y = groundPosition;
        isJumping = false;
        canDoubleJump = true;
        verticalSpeed = 0;
      }
    }
  }

  void jump() {
    // 이미 점프 중이고 2단 점프가 가능한 경우, 2단 점프 실행
    if (isJumping && canDoubleJump) {
      verticalSpeed = jumpSpeed; // 점프 속도 재설정
      canDoubleJump = false; // 2단 점프 비활성화
    }
    // 아직 점프하지 않은 경우, 첫 번째 점프 실행
    else if (!isJumping) {
      isJumping = true;
      verticalSpeed = jumpSpeed;
    }
  }
}

class Obstacle extends RectangleComponent with HasGameRef<DinoGame> {
  static const double speed = 250; // 장애물 이동 속도
  late final SpriteAnimationComponent animationComponent;
  late double screenWidth;

  Obstacle({required Vector2 position, required double screenHeight})
      : super(
            position: position,
            size: Vector2(60, 45),
            anchor: Anchor.bottomRight,
            paint: Paint()..color = Colors.transparent);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    screenWidth = gameRef.size.x;
    final spriteSheet = await gameRef.images.load('Rhinoceros(52x34).png');
    final spriteAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.05,
        textureSize: Vector2(52, 34),
      ),
    );

    animationComponent = SpriteAnimationComponent(
      animation: spriteAnimation,
      position: Vector2(0, -14),
      size: Vector2.all(62),
    );

    add(animationComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    x -= speed * dt;

    if (x + width < 0) {
      removeFromParent();
    }
  }
}

class ScoreComponent extends TextComponent with HasGameRef<DinoGame> {
  int score = 0;
  double timeAccumulator = 0;

  ScoreComponent() : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    text = 'Score: $score';

    position = Vector2(gameRef.size.x / 2.1, 20);
  }

  @override
  void update(double dt) {
    if (gameRef.isGameRunning) {
      super.update(dt);
      timeAccumulator += dt;
      while (timeAccumulator >= 1) {
        score++;
        timeAccumulator -= 1;
        text = 'Score: $score';
      }
    }
  }

  void resetScore() {
    score = 0;
    text = 'Score: $score';
  }
}
