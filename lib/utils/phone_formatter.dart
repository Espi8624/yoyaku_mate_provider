class PhoneFormatter {
  // UI表示用（スペース区切り）
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
    } else if (digitsOnly.length == 10) {
      // 10桁の場合：03, 04, 06 等の2桁市外局番判定 (簡易的な判定)
      // 03, 06, 02(Seoul/Some JP) は 2-4-4
      if (digitsOnly.startsWith('03') ||
          digitsOnly.startsWith('06') ||
          digitsOnly.startsWith('02')) {
        return '${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 6)} ${digitsOnly.substring(6)}';
      }
      // その他(011, 045等)は 3-3-4
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
    } else {
      // 11桁以上 (090等) -> 3-4-4
      final parts = [
        digitsOnly.substring(0, 3),
        digitsOnly.substring(3, 7),
        digitsOnly.substring(
            7, digitsOnly.length > 11 ? 11 : digitsOnly.length),
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
    } else if (digitsOnly.length == 10) {
      // 10桁の場合：03, 04, 06 等の2桁市外局番判定
      if (digitsOnly.startsWith('03') ||
          digitsOnly.startsWith('06') ||
          digitsOnly.startsWith('02')) {
        return '${digitsOnly.substring(0, 2)}-${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
      }
      // その他は 3-3-4
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else {
      // 11桁以上 -> 3-4-4
      final parts = [
        digitsOnly.substring(0, 3),
        digitsOnly.substring(3, 7),
        digitsOnly.substring(
            7, digitsOnly.length > 11 ? 11 : digitsOnly.length),
      ];
      return parts.where((part) => part.isNotEmpty).join('-');
    }
  }

  // 数字のみを取得（APIへの送信時など）
  static String getDigitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
}
