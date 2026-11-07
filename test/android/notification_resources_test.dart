import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/design/tokens.dart';

const _res = 'android/app/src/main/res';

String _read(String path) => File(path).readAsStringSync();

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();

void main() {
  final manifest = _read('android/app/src/main/AndroidManifest.xml');

  test('the manifest declares the permission and the three FCM defaults', () {
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    for (final name in [
      'com.google.firebase.messaging.default_notification_channel_id',
      'com.google.firebase.messaging.default_notification_icon',
      'com.google.firebase.messaging.default_notification_color',
    ]) {
      expect(manifest, contains(name));
    }
    expect(manifest, contains('@drawable/ic_stat_tiyn'));
    expect(manifest, contains('@color/notification_navy'));
  });

  test('the channel id is the same in the manifest and in Kotlin', () {
    final kotlin = _read(
      'android/app/src/main/kotlin/kz/tiyn/app/NotificationChannels.kt',
    );
    final id = RegExp(r'const val ID = "(\w+)"').firstMatch(kotlin)?.group(1);
    expect(id, 'tiyn');
    expect(manifest, contains('android:value="$id"'));
  });

  test('the notification colour is the brand navy', () {
    final colors = _read('$_res/values/colors.xml');
    expect(colors, contains('name="notification_navy">${_hex(Palette.navy)}<'));
  });

  test('the channel name exists in every language', () {
    for (final dir in ['values', 'values-ru', 'values-kk']) {
      final strings = _read('$_res/$dir/strings.xml');
      expect(
        strings,
        contains('name="notification_channel_name"'),
        reason: dir,
      );
    }
  });

  test('the small icon is a white shape, never a coloured one', () {
    final icon = _read('$_res/drawable/ic_stat_tiyn.xml');
    final fills = RegExp(r'fillColor="(#\w+)"').allMatches(icon);
    expect(fills.map((m) => m.group(1)), everyElement('#FFFFFFFF'));
  });
}
