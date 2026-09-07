import 'package:flutter_test/flutter_test.dart';
import 'package:nammaooru_mobile_app/core/utils/form_validators.dart';

void main() {
  group('Indian mobile validation', () {
    test('accepts valid 10-digit mobile numbers starting with 6 to 9', () {
      for (final phone in [
        '6123456789',
        '7123456789',
        '8123456789',
        '9876543210',
      ]) {
        expect(FormValidators.isValidIndianMobile(phone), isTrue);
      }
    });

    test('rejects invalid length, characters, and starting digits', () {
      for (final phone in [
        '',
        '98765',
        '98765432101',
        '1234567890',
        '98765abcde',
        '+919876543210',
      ]) {
        expect(FormValidators.isValidIndianMobile(phone), isFalse);
      }
    });

    test('normalizes country code, leading zero, spaces, and dashes', () {
      expect(
        FormValidators.normalizeIndianMobile('+91 98765-43210'),
        '9876543210',
      );
      expect(
        FormValidators.normalizeIndianMobile('09876543210'),
        '9876543210',
      );
      expect(
        FormValidators.normalizeIndianMobile('98765 43210'),
        '9876543210',
      );
    });
  });

  group('numeric validation', () {
    test('accepts positive prices with up to two decimal places', () {
      for (final price in ['1', '12.5', '12.50', '999999.99']) {
        expect(FormValidators.isValidPositiveDecimal(price), isTrue);
      }
    });

    test('rejects malformed, zero, and negative prices', () {
      for (final price in ['', '0', '0.00', '-1', '12..50', '12.345']) {
        expect(FormValidators.isValidPositiveDecimal(price), isFalse);
      }
    });

    test('requires positive whole numbers', () {
      expect(FormValidators.isValidPositiveInteger('1200'), isTrue);
      expect(FormValidators.isValidPositiveInteger('0'), isFalse);
      expect(FormValidators.isValidPositiveInteger('12.5'), isFalse);
      expect(FormValidators.isValidPositiveInteger('abc'), isFalse);
    });
  });
}
