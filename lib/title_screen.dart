import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/main_screen.dart'; // MainScreenへのパスをインポート

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E6),
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        },
        child: Center(
          child: Image.asset('assets/images/title.png'),
        ),
      ),
    );
  }
}