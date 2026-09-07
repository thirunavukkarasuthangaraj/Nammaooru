class FormValidators {
  FormValidators._();

  static const String mobileExample = 'e.g., 9876543210';

  static final RegExp _indianMobilePattern = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _positiveDecimalPattern = RegExp(r'^\d+(?:\.\d{1,2})?$');

  /// Converts common Indian phone formats to the 10-digit form used by posts.
  /// Unknown formats are returned as digits so validation can reject them.
  static String normalizeIndianMobile(Object? value) {
    var digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return digits;
  }

  static bool isValidIndianMobile(String? value) {
    return _indianMobilePattern.hasMatch(value?.trim() ?? '');
  }

  static bool isValidPositiveDecimal(String? value) {
    final text = value?.trim() ?? '';
    if (!_positiveDecimalPattern.hasMatch(text)) return false;

    final number = double.tryParse(text);
    return number != null && number.isFinite && number > 0;
  }

  static bool isValidPositiveInteger(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number != null && number > 0;
  }
}
