// lib/utils/phone_helper.dart

class PhoneHelper {
  static String normalize(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    if (digits.startsWith('62')) {
      digits = '0${digits.substring(2)}';
    } else if (digits.startsWith('8')) {
      digits = '0$digits';
    }

    if (!digits.startsWith('08')) return '';
    if (digits.length < 10 || digits.length > 13) return '';

    return digits;
  }

  static bool isValid(String phone) => normalize(phone).isNotEmpty;
}