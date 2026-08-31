import 'package:flutter/material.dart';

const Map<String, IconData> _icons = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'sports_esports': Icons.sports_esports,
  'home': Icons.home,
  'payments': Icons.payments,
  'celebration': Icons.celebration,
  'local_hospital': Icons.local_hospital,
  'more_horiz': Icons.more_horiz,
  'redeem': Icons.redeem,
  'pets': Icons.pets,
  'music_note': Icons.music_note,
  'card_travel': Icons.card_travel,
  'flight': Icons.flight,
  'school': Icons.school,
  'phone_iphone': Icons.phone_iphone,
  'shopping_cart': Icons.shopping_cart,
  'savings': Icons.savings,
  'fitness_center': Icons.fitness_center,
};

IconData iconFor(String name) => _icons[name] ?? Icons.category;
