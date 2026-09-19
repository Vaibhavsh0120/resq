import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ResQ's scalable shield-and-heart brand mark.
class ResQBrandMark extends StatelessWidget {
  const ResQBrandMark({super.key, this.size = 48, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      label: 'ResQ',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _MarkPainter()),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Text('ResQ', style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shield = Path()
      ..moveTo(size.width * .5, size.height * .04)
      ..cubicTo(
        size.width * .7,
        size.height * .14,
        size.width * .84,
        size.height * .18,
        size.width * .91,
        size.height * .2,
      )
      ..lineTo(size.width * .86, size.height * .58)
      ..cubicTo(
        size.width * .82,
        size.height * .78,
        size.width * .66,
        size.height * .91,
        size.width * .5,
        size.height * .98,
      )
      ..cubicTo(
        size.width * .34,
        size.height * .91,
        size.width * .18,
        size.height * .78,
        size.width * .14,
        size.height * .58,
      )
      ..lineTo(size.width * .09, size.height * .2)
      ..cubicTo(
        size.width * .25,
        size.height * .16,
        size.width * .38,
        size.height * .1,
        size.width * .5,
        size.height * .04,
      )
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.accent);
    final heart = Path()
      ..moveTo(size.width * .5, size.height * .73)
      ..cubicTo(
        size.width * .43,
        size.height * .65,
        size.width * .27,
        size.height * .55,
        size.width * .27,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .27,
        size.height * .28,
        size.width * .46,
        size.height * .26,
        size.width * .5,
        size.height * .38,
      )
      ..cubicTo(
        size.width * .54,
        size.height * .26,
        size.width * .73,
        size.height * .28,
        size.width * .73,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .73,
        size.height * .55,
        size.width * .57,
        size.height * .65,
        size.width * .5,
        size.height * .73,
      )
      ..close();
    canvas.drawPath(heart, Paint()..color = const Color(0xFFFFFDF8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
