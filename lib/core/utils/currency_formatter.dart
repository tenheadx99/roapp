String formatRupee(
  num value, {
  int decimalDigits = 0,
  bool includeSymbol = true,
}) {
  final absolute = value.abs();
  final fixed = absolute.toStringAsFixed(decimalDigits);
  final parts = fixed.split('.');
  final formattedInteger = _formatIndianDigits(parts.first);
  final decimalPart = decimalDigits > 0 ? '.${parts[1]}' : '';
  final prefix = value < 0 ? '-' : '';
  final symbol = includeSymbol ? '₹' : '';
  return '$prefix$symbol$formattedInteger$decimalPart';
}

String _formatIndianDigits(String digits) {
  if (digits.length <= 3) {
    return digits;
  }

  final lastThree = digits.substring(digits.length - 3);
  var prefix = digits.substring(0, digits.length - 3);
  final groups = <String>[];

  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }

  if (prefix.isNotEmpty) {
    groups.insert(0, prefix);
  }

  return '${groups.join(',')},$lastThree';
}
