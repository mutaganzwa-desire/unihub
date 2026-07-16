import 'package:flutter_test/flutter_test.dart';
import 'package:unihub/core/extensions/string_ext.dart';

void main() {
  test('initials takes up to two uppercase letters', () {
    expect('Amina Hassan'.initials, 'AH');
    expect('single'.initials, 'S');
    expect('a b c d'.initials, 'AB');
  });

  test('searchTokens builds prefixes for starts-with search', () {
    final tokens = 'Flutter Dev'.searchTokens;
    expect(tokens, contains('f'));
    expect(tokens, contains('flut'));
    expect(tokens, contains('flutter'));
    expect(tokens, contains('dev'));
    expect(tokens, isNot(contains('x')));
  });

  test('capitalized upper-cases the first letter only', () {
    expect('hello world'.capitalized, 'Hello world');
  });
}
