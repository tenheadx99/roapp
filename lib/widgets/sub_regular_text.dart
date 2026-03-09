import 'package:flutter/material.dart';

class SubRegularText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;

  const SubRegularText({
    super.key,
    required this.text,
    this.textAlign,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize ?? 14,
        fontWeight: FontWeight.w400,
        color: color ?? const Color(0xFF64748B),
        height: 1.625,
      ),
    );
  }
}
