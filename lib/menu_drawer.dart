import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/main_screen.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 64,
              color: const Color(0xFFFF7B00),
              alignment: Alignment.center,
              child: const Text(
                'メニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('ヒントを見る'),
              onTap: () {
                print('ヒントを見る tapped');
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                if (mainScreenState != null) {
                  print('MainScreenState found, calling showHint');
                  mainScreenState.showHint();
                } else {
                  print('MainScreenState not found');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ヒントを表示できませんでした')),
                  );
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('遊び方'),
              onTap: () {
                print('遊び方 tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('遊び方が選択されました')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu),
              title: const Text('メニュー3'),
              onTap: () {
                print('メニュー3 tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メニュー3が選択されました')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}