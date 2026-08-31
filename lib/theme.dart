import 'package:flutter/material.dart';

// 主题由主色种子驱动，主色从外观配置读取，方便后续多主题切换
ThemeData buildTheme(Color seedColor) {
  final scheme = ColorScheme.fromSeed(seedColor: seedColor);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFBF7F7),
    splashFactory: InkRipple.splashFactory,
  );
}
