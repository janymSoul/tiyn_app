import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiyn_app/design/theme.dart';
import 'package:tiyn_app/design/widgets/state_chip.dart';
import 'package:tiyn_app/features/tasks/data/task_state.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

void main() {
  test('every state has its own colours', () {
    final seen = <(Color, Color)>{};
    for (final s in TaskState.values) {
      final c = StateChip.colors(s);
      expect(seen.add((c.background, c.foreground)), isTrue, reason: '$s');
    }
  });

  test('text is readable on every chip (contrast >= 4.5)', () {
    double luminance(Color c) => c.computeLuminance();
    for (final s in TaskState.values) {
      final c = StateChip.colors(s);
      final hi = luminance(c.background) > luminance(c.foreground)
          ? c.background
          : c.foreground;
      final lo = hi == c.background ? c.foreground : c.background;
      final ratio = (luminance(hi) + 0.05) / (luminance(lo) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: '$s: $ratio');
    }
  });

  for (final locale in const ['en', 'ru', 'kk']) {
    testWidgets('every state has a word in $locale, all different', (
      tester,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Column(
            children: [for (final s in TaskState.values) StateChip(s)],
          ),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(Column)));
      final labels = [
        for (final s in TaskState.values) StateChip.label(l10n, s),
      ];
      expect(labels.toSet(), hasLength(TaskState.values.length));
      for (final label in labels) {
        expect(label, isNotEmpty);
        expect(find.text(label), findsOneWidget);
      }
    });
  }
}
