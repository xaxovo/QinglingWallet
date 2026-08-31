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
};

IconData iconFor(String name) => _icons[name] ?? Icons.category;
