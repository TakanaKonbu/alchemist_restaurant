import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/models/item_data.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedDropdownValue = 'すべて';
  static const Color accentColor = Color(0xFFFF7B00);
  static const Color emptySlotColor = Colors.grey;

  // 全ての初期アイテム（ゲーム開始時に利用可能なアイテム）
  final List<ItemData> _allInitialItems = [
    ItemData(id: 'hi', name: '火', category: '調理', imagePath: 'assets/images/hi.png'),
    ItemData(id: 'mizu', name: '水', category: '調理', imagePath: 'assets/images/mizu.png'),
    ItemData(id: 'komugi', name: '小麦', category: '素材', imagePath: 'assets/images/komugi.png'),
    ItemData(id: 'kome', name: '米', category: '素材', imagePath: 'assets/images/kome.png'),
    ItemData(id: 'tamago', name: '卵', category: '素材', imagePath: 'assets/images/tamago.png'),
    ItemData(id: 'sio', name: '塩', category: '素材', imagePath: 'assets/images/sio.png'),
  ];

  // 現在グリッドに表示されているアイテムのリスト（フィルタリングによって変動する可能性がある）
  late List<ItemData> _availableItems;

  // フッターに配置されたアイテムのリスト (最大4つ)
  final List<ItemData?> _footerSlots = List.filled(4, null);

  @override
  void initState() {
    super.initState();
    // アプリ起動時に_availableItemsを初期アイテムで設定
    _availableItems = List.from(_allInitialItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E6),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー部分
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // プルダウンメニュー
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDropdownValue,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDropdownValue = newValue!;
                            });
                            _filterItems(newValue!);
                          },
                          items: <String>['すべて', '調理', '素材', '料理']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                          isExpanded: true,
                          dropdownColor: accentColor,
                        ),
                      ),
                    ),
                  ),
                  // 電球マークのアイコンボタン
                  IconButton(
                    icon: const Icon(Icons.lightbulb_outline),
                    color: accentColor,
                    onPressed: () {
                      print('ヒントボタンが押されました');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ヒントはまだ実装されていません！')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // クエスチョンマークのアイコンボタン
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    color: accentColor,
                    onPressed: () {
                      print('遊び方ボタンが押されました');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('遊び方はまだ実装されていません！')),
                      );
                    },
                  ),
                ],
              ),
            ),
            // メインコンテンツ部分 (スクロール可能な画像グリッド)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: _availableItems.length,
                itemBuilder: (context, index) {
                  final ItemData item = _availableItems[index];
                  return GestureDetector(
                    onTap: () => _addItemToFooter(item),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // フッター部分
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ..._footerSlots.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final ItemData? item = entry.value;
                    return _buildFooterSlot(item, index);
                  }).toList(),
                  _buildStyledIcon(Icons.auto_awesome, _performAlchemy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSlot(ItemData? item, int index) {
    return GestureDetector(
      onTap: () => _clearFooterSlot(index),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item != null ? Colors.transparent : emptySlotColor.withOpacity(0.5),
          shape: BoxShape.circle,
          border: item != null ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: item != null
            ? Image.asset(item.imagePath, fit: BoxFit.contain)
            : Icon(Icons.circle, color: emptySlotColor),
      ),
    );
  }

  Widget _buildCircleIcon(IconData iconData, Color iconColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildStyledIcon(IconData iconData, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _addItemToFooter(ItemData item) {
    setState(() {
      // 同じアイテムを重複して置けるように、contains() のチェックを削除
      for (int i = 0; i < _footerSlots.length; i++) {
        if (_footerSlots[i] == null) {
          _footerSlots[i] = item;
          break; // 最初に見つかった空のスロットに入れる
        }
      }
    });
  }

  void _clearFooterSlot(int index) {
    setState(() {
      _footerSlots[index] = null;
    });
  }

  void _clearAllFooterSlots() {
    setState(() {
      for (int i = 0; i < _footerSlots.length; i++) {
        _footerSlots[i] = null;
      }
    });
  }

  void _performAlchemy() {
    if (_footerSlots.every((item) => item == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('素材を置いてください！')),
      );
      return;
    }

    // フッタースロットのアイテムIDのリストを作成
    // placedItemIds はそのまま使用
    final List<String> placedItemIds =
    _footerSlots.whereType<ItemData>().map((item) => item.id).toList();

    // 錬金レシピの判定のために、ソートされたコピーを作成 (元のリストは変更しない)
    final List<String> sortedPlacedItemIds = List.from(placedItemIds)..sort();


    ItemData? resultItem;

    // --- 錬金レシピのロジック ---
    // 2個グループ
    if (placedItemIds.length == 2) {
      if (sortedPlacedItemIds.contains('hi') && sortedPlacedItemIds.contains('mizu')) {
        resultItem = ItemData(id: 'oyu', name: 'お湯', category: '調理', imagePath: 'assets/images/oyu.png');
      } else if (sortedPlacedItemIds.contains('oyu') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'yudetamago', name: 'ゆで卵', category: '料理', imagePath: 'assets/images/yudetamago.png');
      } else if (sortedPlacedItemIds.contains('kome') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'tamagokakegohan', name: '卵かけご飯', category: '料理', imagePath: 'assets/images/tamagokakegohan.png');
      } else if (sortedPlacedItemIds.contains('komugi') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'kiji', name: '生地', category: '素材', imagePath: 'assets/images/kiji.png');
      } else if (sortedPlacedItemIds.contains('kome') && sortedPlacedItemIds.contains('oyu')) {
        resultItem = ItemData(id: 'okayu', name: 'おかゆ', category: '料理', imagePath: 'assets/images/okayu.png');
      } else if (sortedPlacedItemIds.contains('okayu') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'tamagogayu', name: '卵がゆ', category: '料理', imagePath: 'assets/images/tamagogayu.png');
      } else if (sortedPlacedItemIds.contains('tamago') && sortedPlacedItemIds.contains('hi')) {
        resultItem = ItemData(id: 'tamagoyaki', name: '卵焼き', category: '料理', imagePath: 'assets/images/tamagoyaki.png');
      } else if (sortedPlacedItemIds.contains('kiji') && sortedPlacedItemIds.contains('hi')) {
        resultItem = ItemData(id: 'pan', name: 'パン', category: '料理', imagePath: 'assets/images/pan.png');
      } else if (sortedPlacedItemIds.contains('kiji') && sortedPlacedItemIds.contains('oyu')) {
        resultItem = ItemData(id: 'men', name: '麺', category: '素材', imagePath: 'assets/images/men.png');
      } else if (placedItemIds.where((id) => id == 'pan').length == 2) { // パン + パン = パン粉 (重複チェック)
        resultItem = ItemData(id: 'panko', name: 'パン粉', category: '素材', imagePath: 'assets/images/panko.png');
      } else if (sortedPlacedItemIds.contains('pan') && sortedPlacedItemIds.contains('hi')) { // パン + 火 = トースト
        resultItem = ItemData(id: 'to-suto', name: 'トースト', category: '料理', imagePath: 'assets/images/to-suto.png');
      } else if (sortedPlacedItemIds.contains('sio') && sortedPlacedItemIds.contains('kome')) {
        resultItem = ItemData(id: 'onigiri', name: 'おにぎり', category: '料理', imagePath: 'assets/images/onigiri.png');
      } else if (sortedPlacedItemIds.contains('onigiri') && sortedPlacedItemIds.contains('hi')) {
        resultItem = ItemData(id: 'yakionigiri', name: '焼きおにぎり', category: '料理', imagePath: 'assets/images/yakionigiri.png');
      } else if (sortedPlacedItemIds.contains('yudetamago') && sortedPlacedItemIds.contains('to-suto')) {
        resultItem = ItemData(id: 'to-sutoeggu', name: 'トーストエッグ', category: '料理', imagePath: 'assets/images/to-sutoeggu.png');
      } else if (sortedPlacedItemIds.contains('kiji') && sortedPlacedItemIds.contains('hi') && !placedItemIds.contains('pan')) { // クッキーも生地+火だが、パンと競合しないように
        resultItem = ItemData(id: 'kukki-', name: 'クッキー', category: '料理', imagePath: 'assets/images/kukki-.png');
      } else if (sortedPlacedItemIds.contains('yudetamago') && sortedPlacedItemIds.contains('syouyu')) {
        resultItem = ItemData(id: 'nitamago', name: '煮卵', category: '料理', imagePath: 'assets/images/nitamago.png');
      } else if (sortedPlacedItemIds.contains('pan') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'hurentito-suto', name: 'フレンチトースト', category: '料理', imagePath: 'assets/images/hurentito-suto.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('hi')) {
        resultItem = ItemData(id: 'yakitori', name: '焼き鳥', category: '料理', imagePath: 'assets/images/yakitori.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('abura')) {
        resultItem = ItemData(id: 'karaage', name: 'からあげ', category: '料理', imagePath: 'assets/images/karaage.png');
      }

    }
    // 3個グループ
    else if (placedItemIds.length == 3) {
       if (sortedPlacedItemIds.contains('men') && sortedPlacedItemIds.contains('oyu') && sortedPlacedItemIds.contains('syouyu')) {
        resultItem = ItemData(id: 'syouyu_ra-men', name: '醤油ラーメン', category: '料理', imagePath: 'assets/images/syouyu_ra-men.png');
      } else if (sortedPlacedItemIds.contains('men') && sortedPlacedItemIds.contains('oyu') && sortedPlacedItemIds.contains('sio')) {
        resultItem = ItemData(id: 'sio_ra-men', name: '塩ラーメン', category: '料理', imagePath: 'assets/images/sio_ra-men.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('hi') && sortedPlacedItemIds.contains('syouyu')) {
        resultItem = ItemData(id: 'teriyakitikin', name: 'てりやきチキン', category: '料理', imagePath: 'assets/images/teriyakitikin.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('kome') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'oyakodon', name: '親子丼', category: '料理', imagePath: 'assets/images/oyakodon.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('oyu') && sortedPlacedItemIds.contains('sio')) {
        resultItem = ItemData(id: 'tikinsu-pu', name: 'チキンスープ', category: '素材', imagePath: 'assets/images/tikinsu-pu.png');
      } else if (sortedPlacedItemIds.contains('toriniku') && sortedPlacedItemIds.contains('abura') && sortedPlacedItemIds.contains('panko')) {
        resultItem = ItemData(id: 'tikinkatu', name: 'チキンカツ', category: '料理', imagePath: 'assets/images/tikinkatu.png');
      } else if (sortedPlacedItemIds.contains('yakitori') && sortedPlacedItemIds.contains('kome') && sortedPlacedItemIds.contains('tamago')) {
        resultItem = ItemData(id: 'yakitoridon', name: '焼き鳥丼', category: '料理', imagePath: 'assets/images/yakitoridon.png');
      }
    }

    if (resultItem != null) {
      if (!_availableItems.contains(resultItem)) {
        setState(() {
          _availableItems.add(resultItem!);
          _availableItems.sort((a, b) => a.id.compareTo(b.id));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} を発見しました！')),
        );

        // アンロックロジック（仮）
        if (_availableItems.length >= 10 && !_availableItems.any((item) => item.id == 'syouyu')) {
          setState(() {
            _availableItems.add(ItemData(id: 'syouyu', name: '醤油', category: '素材', imagePath: 'assets/images/syouyu.png'));
            _availableItems.add(ItemData(id: 'satou', name: '砂糖', category: '素材', imagePath: 'assets/images/satou.png'));
            _availableItems.sort((a, b) => a.id.compareTo(b.id));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('新しい素材「醤油」と「砂糖」をアンロックしました！')),
          );
        }
        if (_availableItems.length >= 20 && !_availableItems.any((item) => item.id == 'toriniku')) {
          setState(() {
            _availableItems.add(ItemData(id: 'toriniku', name: '鶏肉', category: '素材', imagePath: 'assets/images/toriniku.png'));
            _availableItems.sort((a, b) => a.id.compareTo(b.id));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('新しい素材「鶏肉」をアンロックしました！')),
          );
        }
        if (_availableItems.length >= 25 && !_availableItems.any((item) => item.id == 'abura')) {
          setState(() {
            _availableItems.add(ItemData(id: 'abura', name: '油', category: '調理', imagePath: 'assets/images/abura.png'));
            _availableItems.sort((a, b) => a.id.compareTo(b.id));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('新しい調理「油」をアンロックしました！')),
          );
        }
        if (_availableItems.length >= 30 && !_availableItems.any((item) => item.id == 'yasai')) {
          setState(() {
            _availableItems.add(ItemData(id: 'yasai', name: '野菜', category: '素材', imagePath: 'assets/images/yasai.png'));
            _availableItems.sort((a, b) => a.id.compareTo(b.id));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('新しい素材「野菜」をアンロックしました！')),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} はすでに発見済みです！')),
        );
      }
      _clearAllFooterSlots();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この組み合わせからは何も生まれませんでした...')),
      );
      _clearAllFooterSlots();
    }
  }

  void _filterItems(String category) {
    setState(() {
      final List<ItemData> allDiscoveredItems = List.from(_allInitialItems);
      for (var item in _availableItems) {
        if (!allDiscoveredItems.contains(item)) {
          allDiscoveredItems.add(item);
        }
      }

      if (category == 'すべて') {
        _availableItems = allDiscoveredItems;
      } else {
        _availableItems = allDiscoveredItems.where((item) => item.category == category).toList();
      }
      _availableItems.sort((a, b) => a.id.compareTo(b.id));
    });
  }
}