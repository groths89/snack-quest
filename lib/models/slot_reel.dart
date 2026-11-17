import 'snack_item.dart';

class SlotReel {
  const SlotReel({
    required this.title,
    required this.icon,
    required this.category,
  });

  final String title;
  final String icon;
  final SnackCategory category;

  static const reels = [
    SlotReel(title: 'Crunch', icon: '🥨', category: SnackCategory.crunch),
    SlotReel(title: 'Dip', icon: '🧀', category: SnackCategory.protein),
    SlotReel(title: 'Sip', icon: '🧃', category: SnackCategory.drink),
  ];
}
