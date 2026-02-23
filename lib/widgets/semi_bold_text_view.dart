import 'package:flutter/material.dart';

class SemiBoldTextView extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SemiBoldTextView({
    super.key,
    required this.text,
    this.color,
    this.fontSize = 14,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: color ?? const Color(0xFF0F172A), // Tailwind slate-900
      ),
    );
  }
}
