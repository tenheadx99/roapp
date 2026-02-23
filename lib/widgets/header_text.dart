import 'package:flutter/material.dart';

class HeaderText extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HeaderText({
    super.key,
    required this.text,
    this.color,
    this.fontSize = 24, // Matches typical h1/h2
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
        fontWeight: FontWeight.w800, // Extrabold from the login screen
        fontSize: fontSize,
        color: color ?? const Color(0xFF0F172A), // Tailwind slate-900
        letterSpacing: -0.5, // tracking-tight
      ),
    );
  }
}
