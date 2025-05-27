class ItemData {
  final String id;
  final String name;
  final String category;
  final String imagePath;

  ItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ItemData &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}