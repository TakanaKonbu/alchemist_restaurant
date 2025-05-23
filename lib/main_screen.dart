import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/models/item_data.dart'; // 新しく作成したItemDataをインポート

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedDropdownValue = 'すべて'; // 初期値

  // アイコンと同じ色を定数として定義
  static const Color accentColor = Color(0xFFFF7B00);
  static const Color emptySlotColor = Colors.grey; // 空のスロットの色

  // 現在利用可能なアイテムのリスト（ゲーム開始時の初期アイテム）
  // ItemDataオブジェクトのリストに変更
  final List<ItemData> _availableItems = [
    ItemData(id: 'hi', name: '火', category: '調理', imagePath: 'assets/images/hi.png'),
    ItemData(id: 'mizu', name: '水', category: '調理', imagePath: 'assets/images/mizu.png'),
    ItemData(id: 'komugi', name: '小麦', category: '素材', imagePath: 'assets/images/komugi.png'),
    ItemData(id: 'kome', name: '米', category: '素材', imagePath: 'assets/images/kome.png'),
    ItemData(id: 'tamago', name: '卵', category: '素材', imagePath: 'assets/images/tamago.png'),
    ItemData(id: 'sio', name: '塩', category: '素材', imagePath: 'assets/images/sio.png'),
    // お湯が初期から使えるように、または錬金で生成されるように
    // 例として、初期アイテムにお湯を追加する場合（通常は錬金で生成されます）
    // ItemData(id: 'oyu', name: 'お湯', category: '調理', imagePath: 'assets/images/oyu.png'),
  ];

  // フッターに配置されたアイテムのリスト (最大4つ)
  final List<ItemData?> _footerSlots = List.filled(4, null); // nullで初期化

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
                        borderRadius: BorderRadius.circular(10.0), // 角の丸み
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDropdownValue,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // アイコンの色も白に
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.white, fontSize: 18), // 文字色を白に
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDropdownValue = newValue!;
                            });
                            _filterItems(newValue!); // ドロップダウン選択でアイテムをフィルタリング
                          },
                          items: <String>['すべて', '調理', '素材', '料理']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0), // 左に余白を追加
                                child: Text(
                                  value,
                                  style: const TextStyle(color: Colors.white), // ドロップダウンリスト内の文字色も白に
                                ),
                              ),
                            );
                          }).toList(),
                          isExpanded: true,
                          dropdownColor: accentColor, // ドロップダウンリスト自体の背景色も変更
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
                    },
                  ),
                  const SizedBox(width: 8),
                  // クエスチョンマークのアイコンボタン
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    color: accentColor,
                    onPressed: () {
                      print('遊び方ボタンが押されました');
                    },
                  ),
                ],
              ),
            ),
            // メインコンテンツ部分 (スクロール可能な画像グリッド)
            Expanded( // 残りのスペースを占有し、内部のGridViewをスクロール可能にする
              child: GridView.builder(
                padding: const EdgeInsets.all(10.0), // グリッド全体のパディング
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 1列に5つのアイテムを表示
                  crossAxisSpacing: 10.0, // 列間のスペース
                  mainAxisSpacing: 10.0, // 行間のスペース
                  childAspectRatio: 1.0, // アイテムのアスペクト比 (幅と高さが同じ)
                ),
                itemCount: _availableItems.length,
                itemBuilder: (context, index) {
                  final ItemData item = _availableItems[index];
                  return GestureDetector( // タップを検出するためにGestureDetectorでラップ
                    onTap: () => _addItemToFooter(item),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300), // オプション：画像の境界線
                        borderRadius: BorderRadius.circular(8.0), // オプション：角を丸く
                      ),
                      child: Image.asset(
                        item.imagePath, // ItemDataから画像パスを取得
                        fit: BoxFit.contain, // 画像の表示方法
                      ),
                    ),
                  );
                },
              ),
            ),
            // フッター部分
            Container(
              color: Colors.transparent, // フッター背景は透明（画面背景色が見えるように）
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // 均等に横並び
                children: [
                  // 4つのスロット
                  ..._footerSlots.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final ItemData? item = entry.value;
                    return _buildFooterSlot(item, index);
                  }).toList(),
                  // magicアイコン
                  _buildStyledIcon(Icons.auto_awesome, _performAlchemy), // magicアイコンに処理を追加
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // フッタースロットのウィジェットを生成
  Widget _buildFooterSlot(ItemData? item, int index) {
    return GestureDetector(
      onTap: () => _clearFooterSlot(index), // スロットタップでクリアできるように
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item != null ? Colors.transparent : emptySlotColor.withOpacity(0.5), // アイテムがあれば透明、なければグレー
          shape: BoxShape.circle,
          border: item != null ? Border.all(color: Colors.grey.shade300) : null, // アイテムがあれば枠線
        ),
        child: item != null
            ? Image.asset(item.imagePath, fit: BoxFit.contain)
            : Icon(Icons.circle, color: emptySlotColor), // アイテムがない場合はグレーの丸アイコン
      ),
    );
  }

  // 円形のアイコンウィジェットを生成するヘルパー関数 (フッターのグレー丸)
  Widget _buildCircleIcon(IconData iconData, Color iconColor) {
    return Container(
      width: 40, // 円のサイズ
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.5), // グレーの丸は少し透明に
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor, // アイコン自体の色は指定された色
        size: 24, // アイコンのサイズ
      ),
    );
  }

  // 背景色FF7B00、アイコン色白色のアイコンウィジェットを生成するヘルパー関数
  Widget _buildStyledIcon(IconData iconData, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed, // タップイベントを追加
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accentColor, // 背景色
          shape: BoxShape.circle, // 円形
        ),
        child: Icon(
          iconData,
          color: Colors.white, // アイコン色
          size: 24,
        ),
      ),
    );
  }

  // グリッドのアイテムをタップした時の処理
  void _addItemToFooter(ItemData item) {
    setState(() {
      for (int i = 0; i < _footerSlots.length; i++) {
        if (_footerSlots[i] == null) {
          _footerSlots[i] = item;
          break; // 最初に見つかった空のスロットに入れる
        }
      }
    });
  }

  // フッタースロットのアイテムをクリアする処理
  void _clearFooterSlot(int index) {
    setState(() {
      _footerSlots[index] = null;
    });
  }

  // すべてのフッタースロットをクリアする処理
  void _clearAllFooterSlots() {
    setState(() {
      for (int i = 0; i < _footerSlots.length; i++) {
        _footerSlots[i] = null;
      }
    });
  }

  // 錬金（マジックボタン）のロジック
  void _performAlchemy() {
    // フッタースロットにアイテムが何も置かれていない場合は何もしない
    if (_footerSlots.every((item) => item == null)) {
      return;
    }

    // フッタースロットのアイテムIDのリストを作成
    final List<String> placedItemIds =
    _footerSlots.whereType<ItemData>().map((item) => item.id).toList()..sort(); // 組み合わせ判定のためにソート

    ItemData? resultItem;

    // --- 錬金レシピのロジック ---
    // 例1: 火 + 水 = お湯
    if (placedItemIds.length == 2 && placedItemIds.contains('hi') && placedItemIds.contains('mizu')) {
      resultItem = ItemData(id: 'oyu', name: 'お湯', category: '調理', imagePath: 'assets/images/oyu.png');
    }
    // 例2: お湯 + 卵 = ゆで卵
    else if (placedItemIds.length == 2 && placedItemIds.contains('oyu') && placedItemIds.contains('tamago')) {
      resultItem = ItemData(id: 'yudetamago', name: 'ゆで卵', category: '料理', imagePath: 'assets/images/yudetamago.png');
    }
    // TODO: 他のレシピもここに追加していく

    if (resultItem != null) {
      if (!_availableItems.contains(resultItem)) { // 重複チェック
        setState(() {
          _availableItems.add(resultItem!); // 新しいアイテムを追加
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} を発見しました！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} はすでに発見済みです！')),
        );
      }
      _clearAllFooterSlots(); // 錬金後はスロットをクリア
    } else {
      // 該当するレシピがない場合
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この組み合わせからは何も生まれませんでした...')),
      );
      _clearAllFooterSlots(); // 失敗してもスロットはクリア
    }
  }

  // ドロップダウン選択によるアイテムのフィルタリング
  void _filterItems(String category) {
    // 現在は全アイテムを表示していますが、
    // ここで_availableItemsをフィルタリングするロジックを実装できます。
    // 例:
    // List<ItemData> filteredList;
    // if (category == 'すべて') {
    //   filteredList = allInitialItems; // 元の全アイテムリストに戻す
    // } else {
    //   filteredList = allInitialItems.where((item) => item.category == category).toList();
    // }
    // setState(() {
    //   _availableItems = filteredList;
    // });
    // 現状_availableItemsは画面に表示されているアイテムのみなので、
    // フィルターするためにはゲーム全体のアイテムリスト（_allItemsなど）を別に保持する必要があります。
    // ここでは、フィルタリング機能の基礎だけを残します。
  }
}