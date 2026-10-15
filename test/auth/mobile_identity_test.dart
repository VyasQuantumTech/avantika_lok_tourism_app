import 'package:flutter_test/flutter_test.dart';
import 'package:avantika_lok_tourism_app/core/utils/mobile_identity.dart';
import 'package:avantika_lok_tourism_app/core/utils/validators.dart';

void main() {
  test(
      'Indian national variants resolve to the same identity and pass form validation',
      () {
    for (final value in [
      '7405235056',
      '07405235056',
      '917405235056',
      '+917405235056',
      '+91 74052 35056',
      '00917405235056'
    ]) {
      expect(normalizeMobileIdentity(value), '+917405235056');
      expect(AppValidators.mobile(value), isNull);
    }
    expect(normalizeMobileIdentity('+44 7700 900123'), '+447700900123');
  });
  test('incomplete, malformed and ambiguous numbers fail validation', () {
    for (final value in [
      '',
      '740523505',
      '+012345678',
      'phone',
      '1234567890',
      '7405235056abc'
    ]) {
      expect(() => normalizeMobileIdentity(value), throwsFormatException);
      expect(AppValidators.mobile(value), isNotNull);
    }
  });
}
