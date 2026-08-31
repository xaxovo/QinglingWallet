import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'appearance.dart';

// 保存成功后的纸屑爆发（开源 confetti，本地渲染）
// 时长/粒子/范围等全部从 EffectConfig 读取，便于后续自定义切换
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
    Future.delayed(Duration(milliseconds: widget.effect.durationMs + 400), () {
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
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: e.particles,
          colors: e.colors,
          gravity: e.gravity,
          maxBlastForce: e.blastMax,
          minBlastForce: e.blastMin,
          emissionFrequency: 0.02,
          particleDrag: 0.05,
        ),
      ),
    );
  }
}
