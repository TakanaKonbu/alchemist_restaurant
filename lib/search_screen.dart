import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/models/item_data.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final List<ItemData> availableItems;
  final List<ItemData?> footerSlots;
  final Function(ItemData) onAddItem;

  const SearchScreen({
    super.key,
    required this.availableItems,
    required this.footerSlots,
    required this.onAddItem,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemData> _filteredItems = [];
  String? _message;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.availableItems;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.availableItems.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  bool _canAddToFooter() {
    return widget.footerSlots.any((slot) => slot == null);
  }

  void _showMessage(String message) {
    setState(() {
      _message = message;
    });
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _message = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6E6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'レシピ検索',
                  style: TextStyle(
                    color: Color(0xFFFF7B00),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFFF7B00)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'レシピ名を入力...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7B00)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Color(0xFFFF7B00)),
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AnimatedOpacity(
                opacity: _message != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      color: Color(0xFFFF7B00),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/images/unknown.png'),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFFFF7B00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    item.category,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    if (_canAddToFooter()) {
                      widget.onAddItem(item);
                      _showMessage('${item.name} を追加しました');
                    } else {
                      _showMessage('スロットが満杯です');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}