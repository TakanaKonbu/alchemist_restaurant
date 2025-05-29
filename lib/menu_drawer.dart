import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/main_screen.dart';
import 'package:alchemist_restaurant/howto_screen.dart';

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
                // print('ヒントを見る tapped');
                // Drawerを閉じる前にMainScreenStateを取得
                final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                Navigator.pop(context); // Drawerを閉じる
                if (mainScreenState == null) {
                  // print('MainScreenState not found');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ヒントを表示できませんでした')),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFFFFF6E6),
                      title: const Text(
                        'ヒント',
                        style: TextStyle(
                          color: Color(0xFFFF7B00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text('広告を見てヒントを得ますか？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // print('AdMob: Hint dialog cancelled');
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text(
                            'キャンセル',
                            style: TextStyle(color: Color(0xFFFF7B00)),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // print('AdMob: Hint dialog accepted');
                            Navigator.of(dialogContext).pop();
                            mainScreenState.showAdForHint(context);
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(color: Color(0xFFFF7B00)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('遊び方'),
              onTap: () {
                // print('遊び方 tapped');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HowToScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu),
              title: const Text('メニュー3'),
              onTap: () {
                // print('メニュー3 tapped');
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