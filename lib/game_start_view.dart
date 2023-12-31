import 'package:flutter/material.dart';
import 'package:hackathon/game_screen.dart';

class GameStart extends StatelessWidget {
  const GameStart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/jungleBG.jpg'), // 배경 이미지 설정
            fit: BoxFit.cover, // 화면에 맞게 조정
          ),
        ),
        child: Center(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const GameScreen(), // GameScreen으로 이동
              ));
            },
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Text 테두리
                Text(
                  'GAME START',
                  style: TextStyle(
                    fontSize: 76,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JungleFever',
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 12
                      ..color = Color(0xFF8B4513),
                  ),
                ),
                // 실제 Text
                Text(
                  'GAME START',
                  style: TextStyle(
                    fontSize: 76,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JungleFever',
                    color: Color(0xFFDAA520),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
