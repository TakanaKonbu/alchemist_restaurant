class ItemData {
  final String id; // 画像ファイル名と一致させる (例: 'hi')
  final String name;
  final String category;
  final String imagePath; // assets/images/hi.png のような完全パス

  ItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
  });

  // アイテムの比較用 (例: リストに同じアイテムが追加されないようにするため)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}