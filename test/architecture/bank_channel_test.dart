import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only core/bank talks to the bank channel', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('lib/core/bank/') &&
            f.readAsStringSync().contains('kz.tiyn.app/banks'))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('nothing but core/bank and main builds the real launcher', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('lib/core/bank/') &&
            !f.path.endsWith('lib/main.dart') &&
            f.readAsStringSync().contains('MethodChannelBankLauncher'))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
