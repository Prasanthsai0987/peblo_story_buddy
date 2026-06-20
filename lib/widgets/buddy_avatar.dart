// lib/widgets/buddy_avatar.dart  — REPLACE the entire existing file with this
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

enum BuddyMood { neutral, listening, happy, confused }

/// A lightweight, vector-drawn buddy. No image/Lottie assets needed (cheap
/// on low-RAM devices), but animated: blinks + bobs while idle, flaps its
/// mouth in rhythm while "speaking", bounces happily on a correct answer.
class BuddyAvatar extends StatefulWidget {
  const BuddyAvatar({super.key, required this.mood, this.size = 150});

  final BuddyMood mood;
  final double size;

  @override
  State<BuddyAvatar> createState() => _BuddyAvatarState();
}

class _BuddyAvatarState extends State<BuddyAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _talkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(covariant BuddyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isTalking = widget.mood == BuddyMood.listening;
    final wasTalking = oldWidget.mood == BuddyMood.listening;
    if (isTalking && !wasTalking) {
      _talkController.repeat(reverse: true);
    } else if (!isTalking && wasTalking) {
      _talkController.stop();
      _talkController.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.mood == BuddyMood.listening) {
      _talkController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final happy = widget.mood == BuddyMood.happy;

    return AnimatedScale(
      scale: happy ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _talkController]),
        builder: (context, _) {
          final bob = happy
              ? 0.0
              : sin(_idleController.value * 2 * pi) * (widget.size * 0.02);

          final blink = !happy &&
              widget.mood != BuddyMood.confused &&
              (_idleController.value > 0.92 && _idleController.value < 0.97);

          return Transform.translate(
            offset: Offset(0, bob),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC93C).withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: happy ? 10 : 4,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _BuddyPainter(
                  mood: widget.mood,
                  mouthOpen: _talkController.value,
                  blink: blink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({required this.mood, required this.mouthOpen, required this.blink});

  final BuddyMood mood;
  final double mouthOpen;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.42;

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: const [Color(0xFFFFE08A), Color(0xFFFFC93C)],
      ).createShader(Rect.fromCircle(center: center, radius: headRadius));
    canvas.drawCircle(center, headRadius, bodyPaint);

    canvas.drawCircle(
      center,
      headRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.5),
    );

    final antennaTop = Offset(center.dx, center.dy - headRadius - 18);
    canvas.drawLine(
      Offset(center.dx, center.dy - headRadius),
      antennaTop,
      Paint()
        ..color = const Color(0xFFFF6B6B)
        ..strokeWidth = 4,
    );
    canvas.drawCircle(antennaTop, 6, Paint()..color = const Color(0xFFFF6B6B));

    final eyeColor = Paint()..color = const Color(0xFF2D2A4A);
    final eyeOffsetX = headRadius * 0.42;
    final eyeY = center.dy - headRadius * 0.05;

    if (mood == BuddyMood.confused) {
      final p = Paint()
        ..color = const Color(0xFF2D2A4A)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx - eyeOffsetX - 8, eyeY),
          Offset(center.dx - eyeOffsetX + 8, eyeY - 6), p);
      canvas.drawLine(Offset(center.dx + eyeOffsetX - 8, eyeY - 6),
          Offset(center.dx + eyeOffsetX + 8, eyeY), p);
    } else if (blink) {
      final p = Paint()
        ..color = const Color(0xFF2D2A4A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx - eyeOffsetX - 7, eyeY),
          Offset(center.dx - eyeOffsetX + 7, eyeY), p);
      canvas.drawLine(Offset(center.dx + eyeOffsetX - 7, eyeY),
          Offset(center.dx + eyeOffsetX + 7, eyeY), p);
    } else {
      final eyeRadius = mood == BuddyMood.happy ? headRadius * 0.1 : headRadius * 0.12;
      canvas.drawCircle(Offset(center.dx - eyeOffsetX, eyeY), eyeRadius, eyeColor);
      canvas.drawCircle(Offset(center.dx + eyeOffsetX, eyeY), eyeRadius, eyeColor);
      final hi = Paint()..color = Colors.white.withOpacity(0.85);
      canvas.drawCircle(
          Offset(center.dx - eyeOffsetX + eyeRadius * 0.35, eyeY - eyeRadius * 0.35),
          eyeRadius * 0.3, hi);
      canvas.drawCircle(
          Offset(center.dx + eyeOffsetX + eyeRadius * 0.35, eyeY - eyeRadius * 0.35),
          eyeRadius * 0.3, hi);
    }

    final mouthCenter = Offset(center.dx, center.dy + headRadius * 0.32);
    final mouthPaint = Paint()
      ..color = const Color(0xFF2D2A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (mood == BuddyMood.happy) {
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: headRadius * 0.7,
        height: headRadius * 0.5,
      );
      canvas.drawArc(mouthRect, 0.2, 2.7, false, mouthPaint);
    } else if (mood == BuddyMood.listening) {
      final openHeight = lerpDouble(6, 22, mouthOpen)!;
      final width = headRadius * 0.42;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: mouthCenter, width: width, height: openHeight),
        const Radius.circular(10),
      );
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2D2A4A));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: mouthCenter.translate(0, openHeight * 0.18),
            width: width * 0.5,
            height: max(2, openHeight * 0.35),
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFFF8A8A),
      );
    } else {
      final mouthRect = Rect.fromCenter(
        center: mouthCenter,
        width: headRadius * 0.6,
        height: headRadius * 0.3,
      );
      canvas.drawLine(
        Offset(mouthRect.left, mouthRect.center.dy),
        Offset(mouthRect.right, mouthRect.center.dy),
        mouthPaint,
      );
    }

    final cheekPaint = Paint()..color = const Color(0x33FF6B6B);
    canvas.drawCircle(Offset(center.dx - headRadius * 0.65, center.dy + headRadius * 0.15),
        headRadius * 0.16, cheekPaint);
    canvas.drawCircle(Offset(center.dx + headRadius * 0.65, center.dy + headRadius * 0.15),
        headRadius * 0.16, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.mouthOpen != mouthOpen ||
      oldDelegate.blink != blink;
}