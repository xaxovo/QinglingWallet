import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'appearance.dart';

// 保存成功后的纸屑爆发（开源 confetti，本地渲染）
// 一次性喷一簇，从屏幕左上角往右下方洒落、落出屏幕底消失；参数全部从 EffectConfig 读取
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

  bool _fade = false;

  @override
  void initState() {
    super.initState();
    final ms = widget.effect.durationMs;
    // 结尾 0.3 秒渐隐淡出，避免残屑突然消失
    Future.delayed(Duration(milliseconds: ms - 300), () {
      if (mounted) setState(() => _fade = true);
    });
    Future.delayed(Duration(milliseconds: ms + 400), () {
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 90,
          height: 90,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fade ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: ConfettiWidget(
                confettiController: _c,
                shouldLoop: false,
                blastDirectionality: e.directional
                    ? BlastDirectionality.directional
                    : BlastDirectionality.explosive,
                blastDirection: e.blastDirection,
                numberOfParticles: e.particles,
                colors: e.colors,
                gravity: e.gravity,
                maxBlastForce: e.blastMax,
                minBlastForce: e.blastMin,
                emissionFrequency: e.emissionFrequency,
                particleDrag: 0.02,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
