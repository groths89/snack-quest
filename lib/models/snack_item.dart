enum SnackCategory {
  crunch('Crunch', '🥨'),
  protein('Dip', '🧀'),
  drink('Drink', '🧃');

  const SnackCategory(this.label, this.defaultEmoji);
  final String label;
  final String defaultEmoji;
}

class SnackItem {
  const SnackItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
  });

  final String id;
  final String name;
  final String emoji;
  final SnackCategory category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'category': category.name,
      };

  factory SnackItem.fromJson(Map<String, dynamic> json) => SnackItem(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        category: SnackCategory.values.byName(json['category'] as String),
      );
}
