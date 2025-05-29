import 'package:flutter/material.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  static const double imageSize = 80;

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStep(
            step: '素材を選んで錬金',
            description: 'グリッドから素材をタップして選びます。\n'
                '火と水を組み合わせてお湯が作れます。\n'
                'このように様々な素材を組み合わせてすべてのレシピを錬金しましょう！',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String step,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: const TextStyle(
            color: Color(0xFFFF7B00),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          description,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/hi.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/unknown.png'),
              ),
              const SizedBox(width: 8.0),
              const Text(
                '+',
                style: TextStyle(
                  color: Color(0xFFFF7B00),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8.0),
              Image.asset(
                'assets/images/mizu.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/unknown.png'),
              ),
              const SizedBox(width: 8.0),
              const Text(
                '=',
                style: TextStyle(
                  color: Color(0xFFFF7B00),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8.0),
              Image.asset(
                'assets/images/oyu.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/unknown.png'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}