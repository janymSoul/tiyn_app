import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';

/// Talks to `MainActivity`. The app is launched by package; if it is not
/// installed, the store page is opened. Package visibility on Android 11+ comes
/// from the manifest's `<queries>`. No package: the same pattern as the
/// notification-settings opener.
class MethodChannelBankLauncher implements BankLauncher {
  const MethodChannelBankLauncher();

  static const channelName = 'kz.tiyn.app/banks';
  static const _channel = MethodChannel(channelName);

  @override
  Future<BankLaunchResult> open(Bank bank) async {
    try {
      final result = await _channel.invokeMethod<String>('open', {
        'package': bank.androidPackage,
      });
      return switch (result) {
        'opened' => BankLaunchResult.opened,
        'store' => BankLaunchResult.storeOpened,
        _ => BankLaunchResult.unavailable,
      };
    } on PlatformException catch (e) {
      // The class only: no amounts, names or ids ever reach a log.
      debugPrint('Could not open a bank app: ${e.code}');
      return BankLaunchResult.unavailable;
    } on MissingPluginException {
      debugPrint('Bank channel is not available');
      return BankLaunchResult.unavailable;
    }
  }
}
