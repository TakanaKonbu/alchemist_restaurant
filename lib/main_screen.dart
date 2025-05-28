import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/models/item_data.dart';
import 'package:alchemist_restaurant/menu_drawer.dart';
import 'package:alchemist_restaurant/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class Recipe {
  final String id;
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedDropdownValue = 'すべて';
  static const Color accentColor = Color(0xFFFF7B00);
  static const Color emptySlotColor = Colors.grey;

  final List<ItemData> _allInitialItems = [];
  List<Recipe> _recipes = [];
  Map<String, String> _nameToIdMap = {};
  late List<ItemData> _availableItems;
  late List<ItemData> _filteredItems;
  final List<ItemData?> _footerSlots = List.filled(4, null);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadProgress();
  }

  Future<void> _loadRecipes() async {
    try {
      final csvString = await rootBundle.loadString('assets/recipe.csv');
      final rows = const CsvToListConverter().convert(csvString, eol: '\n');
      _recipes = rows.skip(1).map((row) {
        final ingredients = [row[1], row[2], row[3], row[4]]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .map((e) => e.toString().trim())
            .toList();
        final imageName = row[6]?.toString().trim() ?? 'unknown';
        final name = row[0]?.toString().trim() ?? '';
        final recipe = Recipe(
          id: imageName,
          name: name,
          ingredients: ingredients,
          unlockCondition: row[5]?.toString().trim() ?? '',
          imagePath: 'assets/images/$imageName.png',
          category: row[7]?.toString().trim() ?? '',
        );
        _nameToIdMap[name] = imageName;
        if (recipe.unlockCondition == '初期') {
          _allInitialItems.add(ItemData(
            id: recipe.id,
            name: recipe.name,
            category: recipe.category,
            imagePath: recipe.imagePath,
          ));
        }
        return recipe;
      }).where((recipe) => recipe.name.isNotEmpty).toList();
      print('Name to ID Map: $_nameToIdMap');
      setState(() {});
    } catch (e) {
      print('Error loading recipes: $e');
    }
  }

  Future<void> _saveProgress({bool showMessage = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_availableItems.map((item) => {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'imagePath': item.imagePath,
    }).toList());
    await prefs.setString('availableItems', itemsJson);
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('availableItems');
    if (itemsJson != null) {
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      setState(() {
        _availableItems = itemsList.map((item) => ItemData(
          id: item['id'],
          name: item['name'],
          category: item['category'],
          imagePath: item['imagePath'],
        )).toList();
        _filteredItems = List.from(_availableItems);
      });
    } else {
      setState(() {
        _availableItems = List.from(_allInitialItems);
        _filteredItems = List.from(_availableItems);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFF6E6),
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 8),
                  Text(
                    '${_availableItems.length}/${_recipes.length}',
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: accentColor,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SearchScreen(
                          availableItems: _availableItems,
                          footerSlots: _footerSlots,
                          onAddItem: _addItemToFooter,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    color: accentColor,
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final ItemData item = _filteredItems[index];
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/unknown.png'),
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
      for (int i = 0; i < _footerSlots.length; i++) {
        if (_footerSlots[i] == null) {
          _footerSlots[i] = item;
          break;
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

    final placedItems = _footerSlots.whereType<ItemData>().toList();
    final placedItemIds = placedItems.map((item) => item.id).toList()..sort();
    ItemData? resultItem;

    for (var recipe in _recipes) {
      final recipeIds = recipe.ingredients
          .map((name) => _nameToIdMap[name])
          .where((id) => id != null)
          .cast<String>()
          .toList()
        ..sort();
      if (placedItemIds.length == recipeIds.length && placedItemIds.join(',') == recipeIds.join(',')) {
        print('Match found: ${recipe.name}, Placed: $placedItemIds, Recipe: $recipeIds');
        resultItem = ItemData(
          id: recipe.id,
          name: recipe.name,
          category: recipe.category,
          imagePath: recipe.imagePath,
        );
        break;
      }
    }

    if (resultItem != null) {
      final alreadyExists = _availableItems.any((item) => item.id == resultItem!.id);
      if (!alreadyExists) {
        setState(() {
          _availableItems.add(resultItem!);
          _filteredItems = List.from(_availableItems);
        });
        _saveProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} を発見しました！')),
        );
        _unlockItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} はすでに発見済みです！')),
        );
      }
      _clearAllFooterSlots();
    } else {
      print('No match: Placed: $placedItemIds');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この組み合わせからは何も生まれませんでした...')),
      );
      _clearAllFooterSlots();
    }
  }

  void _unlockItems() {
    final unlockableItems = _recipes.where((recipe) {
      if (recipe.unlockCondition.contains('作成でアンロック')) {
        final requiredCount = int.tryParse(recipe.unlockCondition.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return _availableItems.length >= requiredCount && !_availableItems.any((item) => item.id == recipe.id);
      }
      return false;
    }).toList();

    if (unlockableItems.isNotEmpty) {
      setState(() {
        for (var recipe in unlockableItems) {
          _availableItems.add(ItemData(
            id: recipe.id,
            name: recipe.name,
            category: recipe.category,
            imagePath: recipe.imagePath,
          ));
        }
        _filteredItems = List.from(_availableItems);
      });
      _saveProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいアイテムをアンロックしました！')),
      );
    }
  }

  void _filterItems(String category) {
    setState(() {
      if (category == 'すべて') {
        _filteredItems = List.from(_availableItems);
      } else {
        _filteredItems = _availableItems.where((item) => item.category == category).toList();
      }
    });
  }
}