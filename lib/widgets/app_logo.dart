import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Branded Expens logo mark (custom E + growth chart).
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool glow;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/brand/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          'assets/brand/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _FallbackMark(size: size),
        ),
      ),
    );

    if (!showWordmark) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.18),
        Text(
          'Expens',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your money, under control',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

/// Vector fallback if brand assets fail to load.
class _FallbackMark extends StatelessWidget {
  final double size;

  const _FallbackMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: CustomPaint(
        painter: _ExpensMarkPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _ExpensMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Bold geometric E
    final left = w * 0.26;
    final right = w * 0.72;
    final top = h * 0.24;
    final bottom = h * 0.76;
    final barH = h * 0.11;
    final stemW = w * 0.14;

    final e = Path()
      ..addRect(Rect.fromLTWH(left, top, right - left, barH))
      ..addRect(Rect.fromLTWH(left, top, stemW, bottom - top))
      ..addRect(
        Rect.fromLTWH(
          left,
          top + (bottom - top - barH) / 2,
          (right - left) * 0.72,
          barH,
        ),
      )
      ..addRect(Rect.fromLTWH(left, bottom - barH, right - left, barH));
    canvas.drawPath(e, ePaint);

    // Rising chart arrow (growth)
    final chart = Paint()
      ..color = const Color(0xFF00695C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p = Path()
      ..moveTo(w * 0.30, h * 0.62)
      ..lineTo(w * 0.42, h * 0.50)
      ..lineTo(w * 0.52, h * 0.56)
      ..lineTo(w * 0.70, h * 0.36);
    canvas.drawPath(p, chart);

    final arrow = Path()
      ..moveTo(w * 0.62, h * 0.36)
      ..lineTo(w * 0.72, h * 0.34)
      ..lineTo(w * 0.68, h * 0.46)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = const Color(0xFF00695C)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
