
import 'package:flutter/services.dart';

class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 8) formatted += ' ';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}