import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 界面效果配置（预留自定义接口：后续多主题 / 界面效果自定义都通过这里改）
class EffectConfig {
  final List<Color> colors;
  final int particles;
  final double gravity;
  final int durationMs;
  final double blastMax;
  final double blastMin;
  final double blastDirection; // 弧度；0=右, 1.57=下
  final bool directional;
  final bool enabled;

  const EffectConfig({
    required this.colors,
    this.particles = 70,
    this.gravity = 0.20,
    this.durationMs = 3000,
    this.blastMax = 14,
    this.blastMin = 6,
    this.blastDirection = 0.9, // 从左上角向右下方洒落
    this.directional = true,
    this.enabled = true,
  });

  EffectConfig copyWith({
    List<Color>? colors,
    int? particles,
    double? gravity,
    int? durationMs,
    double? blastMax,
    double? blastMin,
    double? blastDirection,
    bool? directional,
    bool? enabled,
  }) =>
      EffectConfig(
        colors: colors ?? this.colors,
        particles: particles ?? this.particles,
        gravity: gravity ?? this.gravity,
        durationMs: durationMs ?? this.durationMs,
        blastMax: blastMax ?? this.blastMax,
        blastMin: blastMin ?? this.blastMin,
        blastDirection: blastDirection ?? this.blastDirection,
        directional: directional ?? this.directional,
        enabled: enabled ?? this.enabled,
      );
}

class AppAppearance {
  final Color seedColor;
  final EffectConfig effect;

  const AppAppearance({required this.seedColor, required this.effect});

  AppAppearance copyWith({Color? seedColor, EffectConfig? effect}) =>
      AppAppearance(
        seedColor: seedColor ?? this.seedColor,
        effect: effect ?? this.effect,
      );
}

class AppAppearanceNotifier extends StateNotifier<AppAppearance> {
  AppAppearanceNotifier()
      : super(const AppAppearance(
          seedColor: Color(0xFFEC9CAF),
          effect: EffectConfig(
            colors: [
              Color(0xFFEC9CAF),
              Color(0xFFF6A7BB),
              Color(0xFFFDE3EA),
              Color(0xFFF8C8D4),
            ],
          ),
        ));

  // —— 预留接口：后续多主题 / 界面效果自定义切换，改这里即可 ——
  void setSeedColor(Color c) => state = state.copyWith(seedColor: c);
  void setEffectColors(List<Color> colors) =>
      state = state.copyWith(effect: state.effect.copyWith(colors: colors));
  void setEffectParticles(int n) =>
      state = state.copyWith(effect: state.effect.copyWith(particles: n));
  void setEffectEnabled(bool v) =>
      state = state.copyWith(effect: state.effect.copyWith(enabled: v));
  void setEffectGravity(double g) =>
      state = state.copyWith(effect: state.effect.copyWith(gravity: g));
}

final appearanceProvider =
    StateNotifierProvider<AppAppearanceNotifier, AppAppearance>(
        (ref) => AppAppearanceNotifier());
