import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
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
  late DinoGame _game;
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
    if (!isGameRunning) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.brown,
              width: 3,
            ),
          ),
          title: const Text(
            'GAME OVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'JungleFever',
              color: Color(0xFFDAA520),
            ),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'ROUND : ${_game.round}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'JungleFever',
                      color: Color(0xFFDAA520),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'SCORE : ${_game.scoreDisplay.score}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'JungleFever',
                      color: Color(0xFFDAA520),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _game.resetGame();
                  startGame();
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.brown,
                    border: Border.all(
                      color: Colors.brown,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'RESTART GAME',
                      style: TextStyle(
                        fontFamily: 'JungleFever',
                        color: Color(0xFFDAA520),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
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
  late RoundComponent roundDisplay;

  late Player player;
  Timer obstacleTimer = Timer(1.5, repeat: false);
  late ScoreComponent scoreDisplay; // 스코어 디스플레이 인스턴스
  double lastObstacleX = double.infinity; // 마지막 장애물의 X 위치
  static const double minObstacleSpacing = 300; // 장애물 간 최소 간격

  int obstaclesCounter = 0; // 생성된 장애물의 수를 추적합니다.
  static const int obstaclesBeforeNextRound =
      5; // 다음 라운드로 가기 전에 생성되어야 하는 장애물의 수입니다.
  bool nextRoundObjectAdded = false; // 다음 라운드 오브젝트가 이미 추가되었는지를 추적합니다.

  int round = 1; // 현재 라운드를 추적하는 변수
  double obstacleSpeedIncrease = 20; // 라운드마다 장애물 속도 증가량
  double obstacleSpeed = 200; // 초기 장애물 속도

  double minSpawnInterval = 0.9; // 최소 장애물 생성 간격
  double maxSpawnInterval = 2.0; // 최대 장애물 생성 간격

  DinoGame({required this.onGameOver, required this.onGameReady});

  @override
  Future<void> onLoad() async {
    super.onLoad();

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
    add(parallaxComponent);

    player = Player(
      position: Vector2(size.x * 0.07, size.y - 60),
      screenHeight: size.y,
    );
    add(player);

    scoreDisplay = ScoreComponent();
    add(scoreDisplay);

    roundDisplay = RoundComponent(round)
      ..position =
          Vector2(scoreDisplay.position.x - 100, scoreDisplay.position.y);
    add(roundDisplay);

    onGameReady();
  }

  void resetObstacleTimer() {
    double interval =
        Random().nextDouble() * (maxSpawnInterval - minSpawnInterval) +
            minSpawnInterval;
    obstacleTimer.stop();
    obstacleTimer = Timer(interval, onTick: addObstacle, repeat: false);
    obstacleTimer.start();
  }

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
      speed: obstacleSpeed,
    );
    if (!nextRoundObjectAdded) {
      add(obstacle);
      lastObstacleX = size.x;
      obstaclesCounter++;
      if (obstaclesCounter == obstaclesBeforeNextRound &&
          !nextRoundObjectAdded) {
        addNextRoundObject();
        nextRoundObjectAdded = true;
      }
    }

    resetObstacleTimer();
  }

  void addNextRoundObject() {
    var nextRoundObject = NextRoundObject(
      position: Vector2(size.x, size.y - 60),
      screenHeight: size.y,
    );
    add(nextRoundObject);
  }

  @override
  void update(double dt) {
    if (isGameRunning) {
      super.update(dt);
      obstacleTimer.update(dt);
      scoreDisplay.update(dt);
    }

    final nextRoundObjects = children.whereType<NextRoundObject>();
    for (final nextRoundObject in nextRoundObjects) {
      if (player.toRect().overlaps(nextRoundObject.toRect())) {
        nextRound();
        remove(nextRoundObject);
        break;
      }
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

  void nextRound() {
    round++;
    roundDisplay.updateRound(round);
    if (maxSpawnInterval > 1) {
      maxSpawnInterval -= 0.1;
    }

    obstacleSpeed += obstacleSpeedIncrease;
    final obstacles = children.whereType<Obstacle>();
    for (var obstacle in obstacles) {
      obstacle.increaseSpeed(obstacleSpeedIncrease); // 속도를 증가
    }

    obstaclesCounter = 0;
    nextRoundObjectAdded = false;
    children.whereType<Obstacle>().forEach((obstacle) {
      remove(obstacle);
    });

    children.whereType<Obstacle>().toList().forEach(remove);
  }

  void startGame() {
    isGameRunning = true;
    round = 1;
    scoreDisplay.resetScore();
    roundDisplay.updateRound(round);

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

    isGameRunning = false;

    maxSpawnInterval = 2.0;
    obstacleSpeed = 200;
    obstaclesCounter = 0;
    nextRoundObjectAdded = false;

    children.whereType<NextRoundObject>().forEach((obstacle) {
      remove(obstacle);
    });

    children.whereType<Obstacle>().forEach((obstacle) {
      remove(obstacle);
    });

    onGameOver();
  }

  void resetGame() {
    player.position = Vector2(size.x * 0.07, size.y - 60);
    player.verticalSpeed = 0;
    player.isJumping = false;
    player.canDoubleJump = true;

    children.whereType<Obstacle>().toList().forEach(remove);

    resetObstacleTimer();

    scoreDisplay.score = 0;
    scoreDisplay.text = 'Score: 0';
  }
}

class Player extends RectangleComponent with HasGameRef<DinoGame> {
  late final SpriteAnimationComponent animationComponent;

  static const double playerSize = 50;
  static const double jumpSpeed = -380;
  double verticalSpeed = 1000;
  double gravity = 800;
  double groundPosition = 540;
  bool isJumping = false;
  bool canDoubleJump = true;

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
    if (isJumping && canDoubleJump) {
      verticalSpeed = jumpSpeed;
      canDoubleJump = false;
    } else if (!isJumping) {
      isJumping = true;
      verticalSpeed = jumpSpeed;
    }
  }
}

class Obstacle extends RectangleComponent with HasGameRef<DinoGame> {
  late double speed;
  late final SpriteAnimationComponent animationComponent;
  late double screenWidth;

  Obstacle(
      {required Vector2 position,
      required double screenHeight,
      this.speed = 200})
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

  void increaseSpeed(double increment) {
    speed += increment;
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

  ScoreComponent()
      : super(
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'JungleFever',
              color: Color(0xFFDAA520),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    text = 'SCORE : $score';

    position = Vector2(gameRef.size.x / 1.14, 20);
  }

  @override
  void update(double dt) {
    if (gameRef.isGameRunning) {
      super.update(dt);
      timeAccumulator += dt;
      while (timeAccumulator >= 1) {
        score++;
        timeAccumulator -= 1;
        text = 'SCORE : $score';
      }
    }
  }

  void resetScore() {
    score = 0;
    text = 'SCORE : $score';
  }
}

class RoundComponent extends TextComponent with HasGameRef<DinoGame> {
  RoundComponent(int round)
      : super(
          text: 'ROUND : $round',
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'JungleFever',
              color: Color(0xFFDAA520),
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    position = Vector2(gameRef.size.x / 1.36, 20);
  }

  void updateRound(int round) {
    text = 'Round: $round';
  }
}

class NextRoundObject extends RectangleComponent with HasGameRef<DinoGame> {
  static const double speed = 170;
  final double screenHeight;
  late final SpriteAnimationComponent animationComponent;

  NextRoundObject({required Vector2 position, required this.screenHeight})
      : super(
            position: position,
            size: Vector2(60, screenHeight),
            anchor: Anchor.bottomRight,
            paint: Paint()..color = Colors.transparent);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final spriteSheet = await gameRef.images.load('MaskRun(32x32).png');
    final spriteAnimation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 11,
        stepTime: 0.05,
        textureSize: Vector2.all(32),
      ),
    );

    animationComponent = FlippedSpriteAnimationComponent(
      animation: spriteAnimation,
      position: Vector2(-8, screenHeight - 54),
      size: Vector2.all(60),
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

class FlippedSpriteAnimationComponent extends SpriteAnimationComponent {
  FlippedSpriteAnimationComponent({
    SpriteAnimation? animation,
    Vector2? position,
    Vector2? size,
  }) : super(
          animation: animation,
          position: position,
          size: size,
          // 나머지 파라미터들...
        );

  @override
  void render(Canvas canvas) {
    canvas.save();

    canvas.translate(size.x, 0);
    canvas.scale(-1.0, 1.0);

    super.render(canvas);

    canvas.restore();
  }
}
