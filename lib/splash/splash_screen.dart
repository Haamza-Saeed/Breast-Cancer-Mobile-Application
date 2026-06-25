import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    _c.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.next),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          return Stack(
            children: [
              // Soft radial glow background
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundGlowPainter(progress: _t.value),
                ),
              ),
              // The ribbon sweeping across
              Positioned.fill(
                child: CustomPaint(
                  painter: _RibbonPainter(progress: _t.value),
                ),
              ),
              // "Breast Cancer Awareness" text fading in
              Center(
                child: Opacity(
                  opacity: (_t.value - 0.6).clamp(0.0, 1.0) / 0.4,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 260),
                      Text(
                        'HOPE',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD63384),
                          letterSpacing: 10,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Breast Cancer Awareness',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFAA3366),
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Soft pink radial glow that pulses in
class _BackgroundGlowPainter extends CustomPainter {
  final double progress;
  _BackgroundGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.9 * progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB6D9).withOpacity(0.35 * progress.clamp(0, 1)),
          const Color(0xFFFFF0F5).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter old) =>
      old.progress != progress;
}

/// Draws a large, realistic breast-cancer pink ribbon sweeping left → right
class _RibbonPainter extends CustomPainter {
  final double progress;
  _RibbonPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;

    // Ribbon scale: big and prominent
    final scale = size.width * 0.0038;

    // Sweep offset: ribbon enters from left off-screen and settles at center
    // progress 0 → x offset is -size.width; at 0.6 it's 0; then stays
    final sweepP = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final xOffset = (1.0 - sweepP) * -size.width * 1.1;

    // Slight arc rise (y drops and settles)
    final yOffset = math.sin(progress * math.pi) * -size.height * 0.05;

    canvas.save();
    canvas.translate(cx + xOffset, cy + yOffset);
    canvas.scale(scale);

    // Slight rotation that settles
    final rotation = (1.0 - sweepP) * -0.3;
    canvas.rotate(rotation);

    _drawRibbon(canvas, size);

    canvas.restore();
  }

  void _drawRibbon(Canvas canvas, Size size) {
    // Pink ribbon drawn in normalized coords (~100 units tall)
    // The classic ribbon shape: two loops at top, tail crossing at bottom

    final pinkFill = Paint()
      ..color = const Color(0xFFFF4FA0)
      ..style = PaintingStyle.fill;

    final pinkDark = Paint()
      ..color = const Color(0xFFCC1F70)
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // ── LEFT LOOP ──
    final leftLoop = Path();
    leftLoop.moveTo(0, 10);
    leftLoop.cubicTo(-20, -40, -80, -40, -60, 10);
    leftLoop.cubicTo(-50, 35, -10, 30, 0, 10);
    leftLoop.close();

    // ── RIGHT LOOP ──
    final rightLoop = Path();
    rightLoop.moveTo(0, 10);
    rightLoop.cubicTo(20, -40, 80, -40, 60, 10);
    rightLoop.cubicTo(50, 35, 10, 30, 0, 10);
    rightLoop.close();

    // ── LEFT TAIL ──
    final leftTail = Path();
    leftTail.moveTo(-5, 20);
    leftTail.cubicTo(-25, 55, -55, 75, -45, 100);
    leftTail.cubicTo(-40, 110, -20, 108, -10, 100);
    leftTail.cubicTo(-15, 80, 5, 55, 5, 30);
    leftTail.close();

    // ── RIGHT TAIL ──
    final rightTail = Path();
    rightTail.moveTo(5, 20);
    rightTail.cubicTo(25, 55, 55, 75, 45, 100);
    rightTail.cubicTo(40, 110, 20, 108, 10, 100);
    rightTail.cubicTo(15, 80, -5, 55, -5, 30);
    rightTail.close();

    // Draw shadows first (slightly offset)
    final shadow = Paint()
      ..color = const Color(0x33CC1F70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.save();
    canvas.translate(4, 6);
    canvas.drawPath(leftLoop, shadow);
    canvas.drawPath(rightLoop, shadow);
    canvas.drawPath(leftTail, shadow);
    canvas.drawPath(rightTail, shadow);
    canvas.restore();

    // Draw main fill
    canvas.drawPath(leftTail, pinkFill);
    canvas.drawPath(rightTail, pinkFill);
    canvas.drawPath(leftLoop, pinkFill);
    canvas.drawPath(rightLoop, pinkFill);

    // Dark shading on inner edges of loops for depth
    final leftShade = Path();
    leftShade.moveTo(0, 10);
    leftShade.cubicTo(-8, -5, -30, -10, -40, 5);
    leftShade.cubicTo(-28, 20, -8, 22, 0, 10);
    leftShade.close();
    canvas.drawPath(leftShade, pinkDark..color = const Color(0x55CC1F70));

    final rightShade = Path();
    rightShade.moveTo(0, 10);
    rightShade.cubicTo(8, -5, 30, -10, 40, 5);
    rightShade.cubicTo(28, 20, 8, 22, 0, 10);
    rightShade.close();
    canvas.drawPath(rightShade, pinkDark..color = const Color(0x55CC1F70));

    // Highlights on loops
    final leftHighlight = Path();
    leftHighlight.moveTo(-15, -20);
    leftHighlight.cubicTo(-35, -35, -60, -28, -50, -10);
    leftHighlight.cubicTo(-35, -15, -20, -10, -15, -20);
    leftHighlight.close();
    canvas.drawPath(leftHighlight, highlight);

    final rightHighlight = Path();
    rightHighlight.moveTo(15, -20);
    rightHighlight.cubicTo(35, -35, 60, -28, 50, -10);
    rightHighlight.cubicTo(35, -15, 20, -10, 15, -20);
    rightHighlight.close();
    canvas.drawPath(rightHighlight, highlight);

    // Center knot circle
    final knotPaint = Paint()
      ..color = const Color(0xFFFF4FA0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 9, knotPaint);
    canvas.drawCircle(
        Offset.zero, 9, Paint()..color = const Color(0xFFCC1F70)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(const Offset(-2, -2), 4, highlight);
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.progress != progress;
}