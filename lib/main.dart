import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/title_screen.dart'; // TitleScreenをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFF6E6)),
        useMaterial3: true,
      ),
      home: const TitleScreen(), // TitleScreenを使用
    );
  }
}