import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/network/error_messages.dart';
import 'package:tiyn_app/l10n/app_localizations_en.dart';
import 'package:tiyn_app/l10n/app_localizations_kk.dart';
import 'package:tiyn_app/l10n/app_localizations_ru.dart';

void main() {
  final en = AppLocalizationsEn();

  test('known codes map to their own messages', () {
    expect(
      apiErrorMessage(en, const ApiException(code: 'invalid_join_code')),
      en.errorInvalidJoinCode,
    );
    expect(
      apiErrorMessage(en, const ApiException(code: 'network_error')),
      en.errorNoConnection,
    );
  });

  test('an unknown code never reaches the user in release mode', () {
    final message = apiErrorMessage(
      en,
      const ApiException(code: 'weird_internal_code', statusCode: 418),
      showCode: false,
    );
    expect(message, 'Something went wrong. Try again.');
    expect(message, isNot(contains('weird_internal_code')));
    expect(message, isNot(contains('_')));
  });

  test('debug builds append the code for developers', () {
    expect(
      apiErrorMessage(
        en,
        const ApiException(code: 'weird_internal_code'),
        showCode: true,
      ),
      'Something went wrong. Try again. (weird_internal_code)',
    );
  });

  test('a non-ApiException gets the generic message, even with showCode', () {
    for (final showCode in [true, false]) {
      expect(
        apiErrorMessage(en, StateError('boom'), showCode: showCode),
        en.errorUnknown,
      );
    }
  });

  test('the generic message has no placeholder in any language', () {
    for (final text in [
      AppLocalizationsEn().errorUnknown,
      AppLocalizationsRu().errorUnknown,
      AppLocalizationsKk().errorUnknown,
    ]) {
      expect(text, isNot(contains('{')));
    }
  });
}
