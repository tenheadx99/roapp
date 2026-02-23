import 'package:flutter/material.dart';

class RegularTextView extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const RegularTextView({
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
        fontFamily: 'Inter', // Assuming Inter based on typical modern design
        fontWeight: FontWeight.w400,
        fontSize: fontSize,
        color: color ?? Colors.black87,
      ),
    );
  }
}
