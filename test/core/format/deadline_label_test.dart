import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/format/deadline_label.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

Future<String> _label(
  WidgetTester tester,
  DateTime deadline,
  DateTime now, {
  String locale = 'en',
}) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = deadlineLabel(
            AppLocalizations.of(context),
            MaterialLocalizations.of(context),
            deadline,
            now: now,
          );
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  // Local wall-clock times, so the test does not depend on the machine's zone.
  final now = DateTime(2026, 11, 7, 9, 30);

  testWidgets('today', (tester) async {
    final deadline = DateTime(2026, 11, 7, 18).toUtc();
    expect(await _label(tester, deadline, now), 'Due today, 18:00');
  });

  testWidgets('just before midnight is still today', (tester) async {
    final deadline = DateTime(2026, 11, 7, 23, 59).toUtc();
    expect(await _label(tester, deadline, now), 'Due today, 23:59');
  });

  testWidgets('tomorrow, even a minute after midnight', (tester) async {
    final deadline = DateTime(2026, 11, 8, 0, 1).toUtc();
    expect(await _label(tester, deadline, now), 'Due tomorrow, 00:01');
  });

  testWidgets('later shows the date', (tester) async {
    final deadline = DateTime(2026, 11, 21, 8, 5).toUtc();
    expect(await _label(tester, deadline, now), 'Due Nov 21, 08:05');
  });

  testWidgets('a past date shows the date too', (tester) async {
    final deadline = DateTime(2026, 11, 3, 18).toUtc();
    expect(await _label(tester, deadline, now), 'Due Nov 3, 18:00');
  });

  testWidgets('the UTC instant is shown in the local zone', (tester) async {
    // 18:00 local, expressed in UTC, must read 18:00 whatever the machine zone.
    final deadline = DateTime(2026, 11, 7, 18).toUtc();
    expect(deadline.isUtc, isTrue);
    expect(await _label(tester, deadline, now), contains('18:00'));
  });

  testWidgets('russian and kazakh', (tester) async {
    final deadline = DateTime(2026, 11, 8, 18).toUtc();
    expect(
      await _label(tester, deadline, now, locale: 'ru'),
      'Срок: завтра, 18:00',
    );
    expect(
      await _label(tester, deadline, now, locale: 'kk'),
      'Мерзімі: ертең, 18:00',
    );
  });
}
