import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'appearance.dart';

// 保存成功后的纸屑爆发（开源 confetti，本地渲染）
// 方向朝上喷射，受重力自然落下、落出屏幕底消失；参数全部从 EffectConfig 读取
void showConfettiBurst(BuildContext context, {required EffectConfig effect}) {
  if (!effect.enabled || effect.colors.isEmpty) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiBurst(effect: effect, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.effect, required this.onDone});
  final EffectConfig effect;
  final VoidCallback onDone;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst> {
  late final ConfettiController _c = ConfettiController(
      duration: Duration(milliseconds: widget.effect.durationMs))
    ..play();

  @override
  void initState() {
    super.initState();
    // 等粒子基本落出屏幕后再移除，避免中途消失
    Future.delayed(Duration(milliseconds: widget.effect.durationMs + 900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.effect;
    return Positioned.fill(
      child: IgnorePointer(
        child: ConfettiWidget(
          confettiController: _c,
          shouldLoop: false,
          blastDirectionality:
              e.directional ? BlastDirectionality.directional : BlastDirectionality.explosive,
          blastDirection: e.blastDirection,
          numberOfParticles: e.particles,
          colors: e.colors,
          gravity: e.gravity,
          maxBlastForce: e.blastMax,
          minBlastForce: e.blastMin,
          emissionFrequency: 0.03,
          particleDrag: 0.02,
        ),
      ),
    );
  }
}
