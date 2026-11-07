import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only core/push imports firebase', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('lib/core/push/') &&
            f.readAsStringSync().contains('package:firebase_'))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
