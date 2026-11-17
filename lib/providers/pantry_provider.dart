import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/snack_item.dart';

class PantryProvider extends ChangeNotifier {
  PantryProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'pantry_v1';

  SharedPreferences? _prefs;
  List<SnackItem> _items = defaultItems();
  bool loaded = false;

  List<SnackItem> get items => List.unmodifiable(_items);

  List<SnackItem> itemsFor(SnackCategory c) =>
      _items.where((i) => i.category == c).toList(growable: false);

  /// Every snack in the pantry, used by the Mystery Grid.
  List<SnackItem> get pool => items;

  static List<SnackItem> defaultItems() {
    var n = 0;
    SnackItem mk(String name, String emoji, SnackCategory c) =>
        SnackItem(id: 'default_${n++}', name: name, emoji: emoji, category: c);
    const c = SnackCategory.crunch,
        p = SnackCategory.protein,
        d = SnackCategory.drink;
    return [
      mk('Apples', '🍎', c),
      mk('Pretzel', '🥨', c),
      mk('Rice Cake', '🍘', c),
      mk('Carrots', '🥕', c),
      mk('Corn Chips', '🌽', c),
      mk('Potato Chips', '🥔', c),
      mk('Goldfish', '🐟', c),
      mk('Almonds', '🌰', c),
      mk('Seed Butter', '🌻', p),
      mk('Avocado Dip', '🥑', p),
      mk('Cheese Cubes', '🧀', p),
      mk('Almond Butter', '🌰', p),
      mk('Cheese Stick', '🧀', p),
      mk('Yogurt', '🍦', p),
      mk('Juice', '🧃', d),
      mk('Chocolate Milk', '🥛', d),
      mk('Berries', '🫐', d),
      mk('Almond Milk', '🥛', d),
      mk('Cheese Stick', '🧀', d),
    ];
  }

  static const _renames = {
    'Apple Slices': 'Apples', 'Pretzels': 'Pretzel', 'Rice Cakes': 'Rice Cake',
    'Baby Carrots': 'Carrots', 'Tortilla Chips': 'Corn Chips', 'Chips': 'Corn Chips',
    'Sunflower Seed Butter': 'Seed Butter', 'Guacamole': 'Avocado Dip',
    'Cheddar Cubes': 'Cheese Cubes', 'String Cheese': 'Cheese Stick',
    'Greek Yogurt': 'Yogurt', 'Apple Juice Box': 'Juice',
    'Choc Milk': 'Chocolate Milk', 'Mixed Berries': 'Berries',
  };

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _items = (jsonDecode(raw) as List)
            .map((e) => SnackItem.fromJson(e as Map<String, dynamic>))
            .map((i) => _renames.containsKey(i.name)
                ? SnackItem(
                    id: i.id,
                    name: _renames[i.name]!,
                    emoji: i.emoji,
                    category: i.category)
                : i)
            .map((i) => i.id.startsWith('default_')
                ? i
                : SnackItem(
                    id: i.id,
                    name: i.name,
                    emoji: _emojiFor(i.name, i.category),
                    category: i.category))
            .where((i) => allergenIn(i.name) == null)
            .toList();
        await _save();
      } catch (_) {
        _items = defaultItems();
      }
    }
    loaded = true;
    notifyListeners();
  }

  static final _allergens = <String, RegExp>{
    'peanuts': RegExp(r'peanut|goober|reese'),
    'tree nuts': RegExp(
        r'\bnuts?\b|cashew|walnut|pecan|pistachio|hazelnut|macadamia|'
        r'chestnut|nutella|praline|marzipan|pesto|coconut|trail mix'),
    'sesame': RegExp(r'sesame|seasame|tahini|hummus|halva|halvah|bagel'),
    'eggs': RegExp(
        r'\beggs?\b|eggnog|mayo|aioli|meringue|custard|quiche|omelet|'
        r'ranch|brownie|waffle|pancake|french toast'),
  };

  /// Returns the allergen a snack name appears to contain, or null if clear.
  static String? allergenIn(String name) {
    final lower = name.toLowerCase();
    for (final e in _allergens.entries) {
      if (e.value.hasMatch(lower)) return e.key;
    }
    return null;
  }

  /// Adds a snack. Returns the blocked allergen name if it was rejected.
  Future<String?> add(String name, SnackCategory category) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final allergen = allergenIn(trimmed);
    if (allergen != null) return allergen;
    _items.add(SnackItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      name: trimmed,
      emoji: _emojiFor(trimmed, category),
      category: category,
    ));
    notifyListeners();
    await _save();
    return null;
  }

  Future<void> remove(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> resetToDefaults() async {
    _items = defaultItems();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  static const _keywords = {
    'almond': '🌰',
    'goldfish': '🐟', 'fish': '🐟', 'potato': '🥔', 'corn chip': '🌽',
    'apple': '🍎', 'banana': '🍌', 'grape': '🍇', 'orange': '🍊',
    'strawberr': '🍓', 'berr': '🫐', 'carrot': '🥕', 'cheese': '🧀',
    'cracker': '🍘', 'cookie': '🍪', 'popcorn': '🍿', 'milk': '🥛',
    'juice': '🧃', 'yogurt': '🍦', 'raisin': '🍇',
    'butter': '🧈', 'pretzel': '🥨', 'chip': '🥔', 'cucumber': '🥒',
    'celery': '🥬', 'water': '💧', 'chocolate': '🍫', 'cereal': '🥣',
    'pear': '🍐', 'melon': '🍉',
  };

  String _emojiFor(String name, SnackCategory c) {
    final lower = name.toLowerCase();
    for (final e in _keywords.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return c.defaultEmoji;
  }
}
