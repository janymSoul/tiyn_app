import 'package:tiyn_app/features/payouts/application/expiry_label.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

String expiryText(AppLocalizations l10n, ExpiryLabel label) =>
    switch (label.unit) {
      ExpiryUnit.days => l10n.payoutDaysLeft(label.count),
      ExpiryUnit.hours => l10n.payoutHoursLeft(label.count),
      ExpiryUnit.lessThanHour => l10n.payoutLessThanHour,
      ExpiryUnit.anyMoment => l10n.payoutAnyMoment,
    };
