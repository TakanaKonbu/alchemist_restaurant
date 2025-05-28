import 'package:flutter/material.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7B00),
        title: const Text(
          '遊び方',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('HowToScreen: Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text(
          '遊び方',
          style: TextStyle(
            color: Color(0xFFFF7B00),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}