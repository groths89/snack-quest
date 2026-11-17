import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snack_quest/models/snack_item.dart';
import 'package:snack_quest/providers/pantry_provider.dart';

void main() {
  test('defaults, add/remove and persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final p = PantryProvider();
    await p.load();
    expect(p.itemsFor(SnackCategory.crunch).length, 8);
    expect(p.itemsFor(SnackCategory.protein).length, 6);
    expect(p.itemsFor(SnackCategory.drink).length, 5);

    await p.add('Banana', SnackCategory.crunch);
    final q = PantryProvider();
    await q.load();
    final banana = q.items.firstWhere((i) => i.name == 'Banana');
    expect(PantryProvider.allergenIn('Peanut Butter'), 'peanuts');
    expect(PantryProvider.allergenIn('Cashews'), 'tree nuts');
    expect(PantryProvider.allergenIn('Hummus'), 'sesame');
    expect(PantryProvider.allergenIn('Hard Boiled Egg'), 'eggs');
    expect(PantryProvider.allergenIn('Apples'), isNull);
    expect(PantryProvider.allergenIn('Almonds'), isNull);
    expect(PantryProvider.allergenIn('Almond Butter'), isNull);
    expect(PantryProvider.allergenIn('Mixed Nuts'), 'tree nuts');
    expect(await p.add('Peanut Butter', SnackCategory.protein), 'peanuts');
    for (final i in PantryProvider.defaultItems()) {
      expect(PantryProvider.allergenIn(i.name), isNull, reason: i.name);
    }
    expect(banana.emoji, '🍌');
    await q.remove(banana.id);
    final r = PantryProvider();
    await r.load();
    expect(r.items.any((i) => i.name == 'Banana'), isFalse);
  });
}
