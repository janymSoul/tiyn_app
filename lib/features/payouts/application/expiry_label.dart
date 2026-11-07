/// How long a request has left, in the coarse steps the UI words.
/// The expiry is the server's `expiresAt`; the client only subtracts the clock.
enum ExpiryUnit { days, hours, lessThanHour, anyMoment }

class ExpiryLabel {
  const ExpiryLabel(this.unit, [this.count = 0]);

  final ExpiryUnit unit;

  /// Days or hours; 0 for the other units.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is ExpiryLabel && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);

  @override
  String toString() => 'ExpiryLabel($unit, $count)';
}

/// Once [expiresAt] has passed the ticker may still take a minute, so the
/// answer is "any moment", never a negative.
ExpiryLabel expiryLabel(DateTime expiresAt, {required DateTime now}) {
  final left = expiresAt.difference(now);
  if (left <= Duration.zero) return const ExpiryLabel(ExpiryUnit.anyMoment);
  if (left.inDays >= 1) return ExpiryLabel(ExpiryUnit.days, left.inDays);
  if (left.inHours >= 1) return ExpiryLabel(ExpiryUnit.hours, left.inHours);
  return const ExpiryLabel(ExpiryUnit.lessThanHour);
}
