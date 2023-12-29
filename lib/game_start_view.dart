import 'package:flutter/material.dart';
import 'package:hackathon/game_screen.dart';

class GameStart extends StatefulWidget {
  const GameStart({super.key});

  @override
  State<GameStart> createState() => _GameStartState();
}

class _GameStartState extends State<GameStart> {
  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const GameScreen()), // GameScreen으로 이동합니다.
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게임 시작'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startGame,
          child: Text('게임 시작'),
        ),
      ),
    );
  }
}
