import 'package:flutter/material.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// "Due today, 18:00" / "Due tomorrow, 18:00" / "Due Nov 21, 18:00", in the
/// device's time zone (the API sends UTC). [now] is a parameter so the day
/// boundaries can be tested.
String deadlineLabel(
  AppLocalizations l10n,
  MaterialLocalizations material,
  DateTime deadline, {
  required DateTime now,
}) {
  final at = deadline.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(at),
    alwaysUse24HourFormat: true,
  );
  return switch (day.difference(today).inDays) {
    0 => l10n.deadlineToday(time),
    1 => l10n.deadlineTomorrow(time),
    _ => l10n.deadlineOn(material.formatShortMonthDay(at), time),
  };
}
