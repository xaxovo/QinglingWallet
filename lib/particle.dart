import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

// 保存成功后的纸屑爆发（开源 confetti 库，纯本地渲染）
// 颜色/数量/开关从外观配置传入，便于后续多主题与效果自定义
void showConfettiBurst(
  BuildContext context, {
  required List<Color> colors,
  required int particles,
  bool enabled = true,
}) {
  if (!enabled || colors.isEmpty) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiBurst(
      colors: colors,
      particles: particles,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({
    required this.colors,
    required this.particles,
    required this.onDone,
  });
  final List<Color> colors;
  final int particles;
  final VoidCallback onDone;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst> {
  late final ConfettiController _c =
      ConfettiController(duration: const Duration(milliseconds: 1100))..play();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
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
    return Positioned.fill(
      child: IgnorePointer(
        child: ConfettiWidget(
          confettiController: _c,
          shouldLoop: false,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: widget.particles,
          colors: widget.colors,
          gravity: 0.25,
          maxBlastForce: 20,
          minBlastForce: 8,
        ),
      ),
    );
  }
}
