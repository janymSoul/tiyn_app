import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/method_channel_bank_launcher.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final manifest = _read('android/app/src/main/AndroidManifest.xml');

  test('every bank in the registry is visible to the app (<queries>)', () {
    // Without it Android 11+ hides the app and it cannot be launched.
    final queries = RegExp(
      r'<queries>(.*?)</queries>',
      dotAll: true,
    ).firstMatch(manifest)?.group(1);
    expect(queries, isNotNull);
    for (final bank in supportedBanks) {
      expect(
        queries,
        contains('<package android:name="${bank.androidPackage}"/>'),
        reason: bank.id,
      );
    }
  });

  test('bank ids and packages are unique', () {
    expect(
      supportedBanks.map((b) => b.id).toSet(),
      hasLength(supportedBanks.length),
    );
    expect(
      supportedBanks.map((b) => b.androidPackage).toSet(),
      hasLength(supportedBanks.length),
    );
  });

  test('the channel name is the same in Dart and Kotlin', () {
    final kotlin = _read('android/app/src/main/kotlin/kz/tiyn/app/BankApps.kt');
    expect(
      kotlin,
      contains(
        'const val CHANNEL = "${MethodChannelBankLauncher.channelName}"',
      ),
    );
    final main = _read(
      'android/app/src/main/kotlin/kz/tiyn/app/MainActivity.kt',
    );
    expect(main, contains('BankApps.CHANNEL'));
  });
}
