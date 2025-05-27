class Recipe {
  final String id; // CSVの画像名をIDとして使用
  final String name;
  final List<String> ingredients;
  final String unlockCondition;
  final String imagePath;
  final String category;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.unlockCondition,
    required this.imagePath,
    required this.category,
  });
}