class PhoneFormatter {
  // UI表示用（スペース区切り）
  static String formatPhoneNumberForDisplay(String value) {
    // 数字以外を除去
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return '';
    }

    // 桁数に応じてフォーマット（スペース区切り）
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 7) {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
    } else {
      final parts = [
        digitsOnly.substring(0, 3),
        digitsOnly.substring(3, 7),
        digitsOnly.substring(7, digitsOnly.length > 11 ? 11 : digitsOnly.length),
      ];
      return parts.where((part) => part.isNotEmpty).join(' ');
    }
  }

  // 内部処理用（ハイフン区切り）
  static String formatPhoneNumberForInternal(String value) {
    // 数字以外を除去
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return '';
    }

    // 桁数に応じてフォーマット（ハイフン区切り）
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 7) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else {
      final parts = [
        digitsOnly.substring(0, 3),
        digitsOnly.substring(3, 7),
        digitsOnly.substring(7, digitsOnly.length > 11 ? 11 : digitsOnly.length),
      ];
      return parts.where((part) => part.isNotEmpty).join('-');
    }
  }

  // 数字のみを取得（APIへの送信時など）
  static String getDigitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
}