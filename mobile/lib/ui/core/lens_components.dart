import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LensLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  const LensLogo({
    super.key,
    this.size = 46,
    this.showWordmark = true,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .34),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [LensColors.aqua, LensColors.indigo, LensColors.violet],
              stops: [0, .55, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: LensColors.indigo.withValues(alpha: .28),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: CustomPaint(painter: _LensMarkPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Text(
            'DegreeLens',
            style: TextStyle(
              color: wordmarkColor ?? LensColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -.55,
              fontSize: size * .46,
            ),
          ),
        ],
      ],
    );
  }
}

class _LensMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * .46, size.height * .44);
    final radius = size.width * .21;
    canvas.drawCircle(center, radius, white);
    canvas.drawLine(
      Offset(center.dx + radius * .68, center.dy + radius * .68),
      Offset(size.width * .72, size.height * .72),
      white,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .55),
      math.pi * 1.05,
      math.pi * .72,
      false,
      white..strokeWidth = size.width * .045,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool dark;

  const AuroraBackground({super.key, required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? LensColors.ink : LensColors.canvas,
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF081126),
                  Color(0xFF151A3E),
                  Color(0xFF101C35),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F8FF), LensColors.canvas],
              ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -110,
            child: _GlowOrb(
              size: 300,
              color: (dark ? LensColors.violet : LensColors.indigo)
                  .withValues(alpha: dark ? .26 : .11),
            ),
          ),
          Positioned(
            top: 260,
            left: -150,
            child: _GlowOrb(
              size: 320,
              color: LensColors.aqua.withValues(alpha: dark ? .17 : .09),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class LensCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const LensCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
        boxShadow: [
          BoxShadow(
            color: LensColors.ink.withValues(alpha: .065),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class GradientPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;

  const GradientPill({
    super.key,
    required this.label,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: .09)
            : LensColors.indigo.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .12)
              : LensColors.indigo.withValues(alpha: .12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: dark ? LensColors.aqua : LensColors.indigo,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? Colors.white : LensColors.indigo,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: LensColors.indigo,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 7),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
      ],
    );
  }
}

class LensLoading extends StatelessWidget {
  final String label;

  const LensLoading({super.key, this.label = 'Bringing your data into focus…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class LensError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const LensError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34, color: LensColors.rose),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
