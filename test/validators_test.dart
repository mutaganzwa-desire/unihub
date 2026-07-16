import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('amina@alueducation.com'), isNull);
      expect(Validators.email('a.b+tag@sub.domain.io'), isNull);
    });
    test('rejects invalid addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires 8+ chars with letters and numbers', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('allletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('matches originals', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('abc12345', 'different'), isNotNull);
    });
  });

  group('Validators.url', () {
    test('is optional but must be a full url when present', () {
      expect(Validators.url(''), isNull);
      expect(Validators.url('https://github.com/amina'), isNull);
      expect(Validators.url('github.com'), isNotNull);
    });
  });
}
