import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/family/presentation/join_code_formatter.dart';

/// Feeds [input] to the formatter the way the framework would: from the
/// [previous] text, so the length difference decides typing versus pasting.
String _format(String input, {String previous = ''}) {
  final result = JoinCodeFormatter().formatEditUpdate(
    TextEditingValue(text: previous),
    TextEditingValue(text: input),
  );
  expect(result.selection, TextSelection.collapsed(offset: result.text.length));
  return result.text;
}

String _typed(String text) {
  var current = '';
  for (final ch in text.split('')) {
    current = _format(current + ch, previous: current);
  }
  return current;
}

void main() {
  group('JoinCodeFormatter', () {
    test('plain typing', () => expect(_typed('SXVPUR'), 'SXVPUR'));

    test('lower case is upper-cased', () => expect(_typed('sxvpur'), 'SXVPUR'));

    test('Russian-layout look-alikes become Latin', () {
      expect(_typed('СХВРУР'), 'CXBPYP');
      expect(_typed('сквмнт'), 'CKBMHT');
    });

    test('spaces and dashes are dropped', () {
      expect(_typed('SX-VP UR'), 'SXVPUR');
    });

    test('I, O, 0 and 1 are dropped', () {
      expect(_typed('SIX0VO1PUR'), 'SXVPUR');
    });

    test('more than 6 characters typed are cut off', () {
      expect(_typed('SXVPURKM'), 'SXVPUR');
    });

    test('English share message gives the last code', () {
      expect(
        _format('Join me on Tiyn. My family code is SXVPUR', previous: ''),
        'SXVPUR',
      );
    });

    test('Russian share message gives the code', () {
      expect(_format('Мой семейный код: SXVPUR'), 'SXVPUR');
    });

    test('a paste with no code falls back to plain cleaning', () {
      expect(_format('hello there', previous: ''), 'HELLTH');
    });

    test('a lower-case code inside a paste is found', () {
      expect(_format('код sxvpur!'), 'SXVPUR');
    });

    test('a second paste replaces the first', () {
      expect(_format('code: KMNPQR', previous: 'SXVPUR'), 'KMNPQR');
    });
  });
}
