import 'package:flutter/material.dart';

class SubRegularText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;

  const SubRegularText({super.key, required this.text, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14, // text-sm
        fontWeight: FontWeight.w400,
        color: Color(0xFF64748B), // text-slate-500
        height: 1.625, // leading-relaxed
      ),
    );
  }
}
