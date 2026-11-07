import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/features/payouts/application/expiry_label.dart';

void main() {
  final now = DateTime.utc(2026, 11, 7, 12);
  ExpiryLabel at(Duration left) => expiryLabel(now.add(left), now: now);

  test('whole days, rounded down', () {
    expect(
      at(const Duration(days: 6, hours: 4)),
      const ExpiryLabel(ExpiryUnit.days, 6),
    );
    expect(at(const Duration(days: 1)), const ExpiryLabel(ExpiryUnit.days, 1));
  });

  test('hours under a day', () {
    expect(
      at(const Duration(hours: 23, minutes: 59)),
      const ExpiryLabel(ExpiryUnit.hours, 23),
    );
    expect(
      at(const Duration(hours: 1)),
      const ExpiryLabel(ExpiryUnit.hours, 1),
    );
  });

  test('under an hour', () {
    expect(
      at(const Duration(minutes: 59, seconds: 59)),
      const ExpiryLabel(ExpiryUnit.lessThanHour),
    );
    expect(
      at(const Duration(seconds: 1)),
      const ExpiryLabel(ExpiryUnit.lessThanHour),
    );
  });

  test('exactly now and past are "any moment", never negative', () {
    expect(at(Duration.zero), const ExpiryLabel(ExpiryUnit.anyMoment));
    expect(
      at(const Duration(minutes: -3)),
      const ExpiryLabel(ExpiryUnit.anyMoment),
    );
    expect(
      at(const Duration(days: -9)),
      const ExpiryLabel(ExpiryUnit.anyMoment),
    );
  });
}
