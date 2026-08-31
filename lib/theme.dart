import 'package:flutter/material.dart';

// 粉白主题，贴合萌系头像的柔粉/奶白调
ThemeData buildTheme() {
  const seed = Color(0xFFEC9CAF);
  final scheme = ColorScheme.fromSeed(seedColor: seed);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFBF7F7),
    splashFactory: InkRipple.splashFactory,
  );
}
