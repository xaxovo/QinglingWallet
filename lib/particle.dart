import 'dart:math' as math;
import 'package:flutter/material.dart';

// 保存成功后的粉色粒子迸发反馈（全局 overlay，短暂显示后自动移除）
void showParticleBurst(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _ParticleBurst(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _ParticleBurst extends StatefulWidget {
  const _ParticleBurst({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<_ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..forward().whenComplete(() {
      if (mounted) widget.onDone();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _BurstPainter(_c, const Color(0xFFEC9CAF))),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.c, this.color);
  final Animation<double> c;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = c.value;
    final rnd = math.Random(7);
    final paint = Paint();
    for (int i = 0; i < 30; i++) {
      final ang = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.4;
      final speed = 240 + rnd.nextDouble() * 300;
      final dx = math.cos(ang) * speed * t;
      final dy = math.sin(ang) * speed * t + 200 * t * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final r = 9 * (1 - t * 0.6);
      final cx = size.width / 2 + dx;
      final cy = size.height * 0.7 + dy;
      paint.color = color.withOpacity(alpha);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
