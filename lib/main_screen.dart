import 'package:flutter/material.dart';
import 'package:alchemist_restaurant/models/item_data.dart';
import 'package:alchemist_restaurant/models/recipe.dart';
import 'package:alchemist_restaurant/menu_drawer.dart';
import 'package:alchemist_restaurant/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:alchemist_restaurant/ad_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class HintData {
  final Recipe recipe;
  final List<String> hintIngredients;

  const HintData({required this.recipe, required this.hintIngredients});
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String _selectedDropdownValue = '全て';
  static const Color accentColor = Color(0xFFFF7B00);
  static const Color emptySlotColor = Colors.grey;

  final List<ItemData> _allInitialItems = [];
  List<Recipe> _recipes = [];
  final Map<String, String> _nameToIdMap = {};
  List<ItemData>? _availableItems;
  List<ItemData>? _filteredItems;
  final List<ItemData?> _footerSlots = List.filled(4, null);
  ItemData? _createdItem;
  HintData? _hintData;
  Timer? _createdItemTimer;
  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: 'bgmPlayer');
  final AudioPlayer _effectPlayer = AudioPlayer(playerId: 'effectPlayer');
  bool _isLoading = true;
  bool _isBgmPlaying = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  int _adLoadAttempts = 0;
  static const int _maxAdLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    final localContext = context;
    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) print('AdMob: MobileAds initialized');
      _loadRewardedAd();
    } catch (e) {
      if (kDebugMode) print('AdMob: Failed to initialize MobileAds: $e');
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('広告の初期化に失敗しました。')),
      );
    }
  }

  void _loadRewardedAd() {
    if (_adLoadAttempts >= _maxAdLoadAttempts) {
      if (kDebugMode) print('AdMob: Max ad load attempts reached ($_maxAdLoadAttempts)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('広告の読み込み試行上限に達しました。後で再度お試しください。')),
      );
      return;
    }

    _adLoadAttempts++;
    if (kDebugMode) print('AdMob: Attempting to load rewarded ad (attempt $_adLoadAttempts, unit: ${AdHelper.rewardedAdUnitId})');
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) print('AdMob: Rewarded ad loaded successfully (unit: ${AdHelper.rewardedAdUnitId})');
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _adLoadAttempts = 0;
          });
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) print('AdMob: Rewarded ad shown');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) print('AdMob: Failed to show rewarded ad: $error');
              ad.dispose();
              setState(() {
                _rewardedAd = null;
                _isAdLoaded = false;
              });
              _loadRewardedAd();
            },
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) print('AdMob: Rewarded ad dismissed');
              ad.dispose();
              setState(() {
                _rewardedAd = null;
                _isAdLoaded = false;
              });
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) print('AdMob: Failed to load rewarded ad: $error');
          setState(() {
            _isAdLoaded = false;
            _rewardedAd = null;
          });
          _loadRewardedAd();
        },
      ),
    );
  }

  void showAdForHint(BuildContext context) {
    if (kDebugMode) print('AdMob: Attempting to show ad (isAdLoaded: $_isAdLoaded, rewardedAd: ${_rewardedAd != null})');
    if (_isAdLoaded && _rewardedAd != null) {
      try {
        _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            if (kDebugMode) print('AdMob: User earned reward: ${reward.amount} ${reward.type}');
            showHint();
          },
        );
      } catch (e) {
        if (kDebugMode) print('AdMob: Error showing rewarded ad: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('広告の表示に失敗しました。後でもう一度お試しください。')),
        );
        setState(() {
          _rewardedAd = null;
          _isAdLoaded = false;
        });
        _loadRewardedAd();
      }
    } else {
      if (kDebugMode) print('AdMob: Ad not loaded or null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('広告を読み込めませんでした。後でもう一度お試しください。')),
      );
      _loadRewardedAd();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (_isBgmPlaying) {
        _bgmPlayer.pause();
        if (kDebugMode) print('BGM paused for background');
        _isBgmPlaying = false;
      }
      _saveProgress();
      if (kDebugMode) print('App paused: Progress saved');
    } else if (state == AppLifecycleState.resumed) {
      if (!_isBgmPlaying) {
        _bgmPlayer.resume();
        if (kDebugMode) print('BGM resumed for foreground');
        _isBgmPlaying = true;
      }
    }
  }

  Future<void> _initializeData() async {
    try {
      await _loadRecipes();
      await _loadProgress();
      await _playBgm();
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Initialized: Available items: ${_availableItems?.length}, Recipes: ${_recipes.length}');
        print('Available items: ${_availableItems?.map((item) => '${item.name} (${item.id})').join(', ')}');
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playBgm() async {
    final localContext = context;
    try {
      await _bgmPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _bgmPlayer.setSource(AssetSource('audio/bgm.mp3'));
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.5);
      await _bgmPlayer.resume();
      _isBgmPlaying = true;
      if (kDebugMode) print('BGM playing: bgm.mp3');
    } catch (e) {
      if (kDebugMode) print('Error playing BGM: $e');
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('BGMの再生に失敗しました。')),
      );
    }
  }

  Future<void> _playEffect(String fileName) async {
    final localContext = context;
    try {
      await _effectPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      final wasBgmPlaying = _bgmPlayer.state == PlayerState.playing;
      await _effectPlayer.setSource(AssetSource('audio/$fileName'));
      await _effectPlayer.setReleaseMode(ReleaseMode.release);
      await _effectPlayer.setVolume(0.8);
      await _effectPlayer.resume();
      if (kDebugMode) print('Effect playing: $fileName');
      if (wasBgmPlaying) {
        _effectPlayer.onPlayerStateChanged.firstWhere((state) => state == PlayerState.completed).then((_) {
          _bgmPlayer.resume();
          if (kDebugMode) print('BGM resumed after effect: $fileName');
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error playing effect $fileName: $e');
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('効果音の再生に失敗しました。')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
    _effectPlayer.dispose();
    _rewardedAd?.dispose();
    _createdItemTimer?.cancel();
    _saveProgress();
    if (kDebugMode) print('App disposed: Progress saved');
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    try {
      final csvString = await rootBundle.loadString('assets/recipe.csv');
      final rows = const CsvToListConverter().convert(csvString, eol: '\n');
      _recipes = rows.skip(1).map((row) {
        final ingredients = [row[1], row[2], row[3], row[4]]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .map((e) => e.toString().trim());
        final imageName = row[6]?.toString().trim() ?? 'unknown';
        final name = row[0]?.toString().trim() ?? '';
        final recipe = Recipe(
          id: imageName,
          name: name,
          ingredients: ingredients.toList(),
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
      if (kDebugMode) print('Recipes loaded: ${_recipes.length}');
      if (kDebugMode) print('Name to ID Map: $_nameToIdMap');
    } catch (e) {
      if (kDebugMode) print('Error loading recipes: $e');
    }
  }

  Future<void> _saveProgress() async {
    final localContext = context;
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = jsonEncode(_availableItems?.map((item) => {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'imagePath': item.imagePath,
      }).toList() ?? []);
      final success = await prefs.setString('availableItems', itemsJson);
      if (kDebugMode) {
        if (success) {
          print('Progress saved: ${itemsJson.length} bytes, items: ${_availableItems?.length}');
        } else {
          print('Failed to save progress');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error saving progress: $e');
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          content: Text('保存に失敗しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('availableItems');
      if (itemsJson != null && itemsJson.isNotEmpty) {
        final List<dynamic> itemsList = jsonDecode(itemsJson);
        _availableItems = itemsList.map((item) {
          return ItemData(
            id: item['id'] as String,
            name: item['name'] as String,
            category: item['category'] as String,
            imagePath: item['imagePath'] as String,
          );
        }).toList();
        if (kDebugMode) print('Progress loaded: ${_availableItems?.length} items');
      } else {
        _availableItems = List.from(_allInitialItems);
        if (kDebugMode) print('No saved progress, using initial items: ${_allInitialItems.length}');
        await _saveProgress();
      }
      _filteredItems = List.from(_availableItems!);
      if (kDebugMode) print('Available items: ${_availableItems?.map((item) => '${item.name} (${item.id})').join(', ')}');
    } catch (e) {
      if (kDebugMode) print('Error loading progress: $e');
      _availableItems = List.from(_allInitialItems);
      _filteredItems = List.from(_availableItems!);
      await _saveProgress();
      if (kDebugMode) print('Fallback to initial items: ${_allInitialItems.length}');
    }
  }

  void showHint() {
    if (kDebugMode) print('showHint called');
    if (_availableItems == null || _availableItems!.isEmpty || _recipes.isEmpty) {
      if (kDebugMode) print('No available items or recipes: items=${_availableItems?.length}, recipes=${_recipes.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ヒントが見つかりません')),
      );
      return;
    }

    final hintRecipe = _findHintRecipe();
    if (hintRecipe == null) {
      if (kDebugMode) print('No hint recipe found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在作れるレシピがありません')),
      );
      return;
    }

    setState(() {
      _hintData = hintRecipe;
      if (kDebugMode) print('Hint data set: ${_hintData!.recipe.name}');
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF6E6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _hintData!.recipe.imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/unknown.png'),
              ),
              const SizedBox(height: 8),
              Text(
                '${_hintData!.recipe.name}のヒント',
                style: const TextStyle(
                  color: Color(0xFFFF7B00),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ..._hintData!.hintIngredients.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              }),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFFF7B00)),
              onPressed: () {
                if (kDebugMode) print('Hint dialog closed');
                Navigator.of(dialogContext).pop();
                setState(() {
                  _hintData = null;
                  if (kDebugMode) print('Hint data cleared');
                });
              },
            ),
          ],
        );
      },
    );
  }

  HintData? _findHintRecipe() {
    if (kDebugMode) print('Finding hint recipe...');
    final availableIds = _availableItems!.map((item) => item.id).toSet();
    if (kDebugMode) print('Available IDs: $availableIds');
    final possibleRecipes = _recipes.where((recipe) {
      final recipeIds = recipe.ingredients
          .map((name) => _nameToIdMap[name])
          .where((id) => id != null)
          .toSet();
      if (kDebugMode) print('Recipe: ${recipe.name}, Ingredients: ${recipe.ingredients}, Required IDs: $recipeIds');
      final hasAllIds = recipeIds.isNotEmpty && recipeIds.every((id) => availableIds.contains(id));
      if (!hasAllIds) {
        if (kDebugMode) print('Recipe ${recipe.name} not possible: missing IDs ${recipeIds.difference(availableIds)}');
        return false;
      }
      if (availableIds.contains(recipe.id)) {
        if (kDebugMode) print('Recipe ${recipe.name} already discovered');
        return false;
      }
      return true;
    }).toList();

    if (possibleRecipes.isEmpty) {
      if (kDebugMode) print('No possible recipes found');
      return null;
    }

    final random = Random();
    final selectedRecipe = possibleRecipes[random.nextInt(possibleRecipes.length)];
    final ingredients = selectedRecipe.ingredients;
    final hintIngredients = ingredients.sublist(0, ingredients.length - 1)
      ..add('？？？');
    if (kDebugMode) print('Hint for ${selectedRecipe.name}: $hintIngredients');
    return HintData(recipe: selectedRecipe, hintIngredients: hintIngredients);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _availableItems == null || _filteredItems == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF6E6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7B00))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E6),
      drawer: const MenuDrawer(),
      body: Stack(
        children: [
          SafeArea(
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
                                  _filterItems();
                                });
                              },
                              items: <String>['全て', '調理', '素材', '料理']
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
                        '${_availableItems!.length}/${_recipes.length}',
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
                              availableItems: _availableItems!,
                              footerSlots: _footerSlots,
                              onAddItem: _addItemToFooter,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          color: accentColor,
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
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
                    itemCount: _filteredItems!.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems![index];
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
                        final index = entry.key;
                        final item = entry.value;
                        return _buildFooterSlot(item, index);
                      }),
                      _buildStyledIcon(Icons.auto_awesome, _performAlchemy),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_createdItem != null)
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _createdItem != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          _createdItem!.imagePath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/unknown.png'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_createdItem!.name} を作成しました',
                          style: const TextStyle(
                            color: Color(0xFFFF7B00),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
          color: item != null ? Colors.transparent : emptySlotColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: item != null ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: item != null
            ? Image.asset(item.imagePath, fit: BoxFit.contain)
            : Icon(Icons.circle, color: emptySlotColor),
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
      for (var i = 0; i < _footerSlots.length; i++) {
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
      for (var i = 0; i < _footerSlots.length; i++) {
        _footerSlots[i] = null;
      }
      if (kDebugMode) print('Slots cleared');
    });
  }

  void _performAlchemy() {
    if (_footerSlots.every((item) => item == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('素材を置いてください！')),
      );
      return;
    }

    final placedItems = _footerSlots.whereType<ItemData>();
    final placedItemIds = placedItems.map((item) => item.id).toList()..sort();
    ItemData? resultItem;

    for (final recipe in _recipes) {
      final recipeIds = recipe.ingredients
          .map((name) => _nameToIdMap[name])
          .whereType<String>()
          .toList()
        ..sort();
      if (placedItemIds.length == recipeIds.length && placedItemIds.join(',') == recipeIds.join(',')) {
        if (kDebugMode) print('Match found: ${recipe.name}, Placed: $placedItemIds, Recipe: $recipeIds');
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
      final alreadyExists = _availableItems!.any((item) => item.id == resultItem!.id);
      if (!alreadyExists) {
        setState(() {
          _availableItems!.add(resultItem!);
          _filteredItems = List.from(_availableItems!);
          _createdItem = resultItem;
        });
        _playEffect('maked.mp3');
        _createdItemTimer?.cancel();
        _createdItemTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _createdItem = null;
            });
          }
        });
        _unlockItems(resultItem);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resultItem.name} はすでに発見済みです！')),
        );
      }
      _clearAllFooterSlots();
    } else {
      if (kDebugMode) print('No match: Placed: $placedItemIds');
      if (kDebugMode) print('Slots kept');
      _playEffect('nothing.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この組み合わせからは何も生まれませんでした...')),
      );
    }
  }

  void _unlockItems(ItemData newItem) {
    final unlockableItems = _recipes.where((recipe) {
      if (recipe.unlockCondition.contains('作成でアンロック')) {
        final requiredCount = int.tryParse(recipe.unlockCondition.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return _availableItems!.length >= requiredCount && !_availableItems!.any((item) => item.id == recipe.id);
      }
      return false;
    }).toList();

    if (unlockableItems.isNotEmpty) {
      setState(() {
        for (final recipe in unlockableItems) {
          _availableItems!.add(ItemData(
            id: recipe.id,
            name: recipe.name,
            category: recipe.category,
            imagePath: recipe.imagePath,
          ));
        }
        _filteredItems = List.from(_availableItems!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しいアイテムをアンロックしました！')),
      );
    }
    _saveProgress();
    if (kDebugMode) print('New item added: ${newItem.name}, Total items: ${_availableItems!.length}');
  }

  void _filterItems() {
    setState(() {
      if (_selectedDropdownValue == '全て') {
        _filteredItems = List.from(_availableItems!);
      } else {
        _filteredItems = _availableItems!.where((item) => item.category == _selectedDropdownValue).toList();
      }
    });
  }
}