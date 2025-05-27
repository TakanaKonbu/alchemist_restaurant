import 'package:flutter/material.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  static const Color accentColor = Color(0xFFFF7B00);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF6E6),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 80,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: accentColor,
              ),
              child: Text(
                'メニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb, color: accentColor),
            title: const Text(
              'ヒントを見る',
              style: TextStyle(color: accentColor, fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context); // Drawerを閉じる
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('メニュー1が選択されました')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: accentColor),
            title: const Text(
              '遊び方',
              style: TextStyle(color: accentColor, fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('メニュー2が選択されました')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: accentColor),
            title: const Text(
              'メニュー3',
              style: TextStyle(color: accentColor, fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('メニュー3が選択されました')),
              );
            },
          ),
        ],
      ),
    );
  }
}