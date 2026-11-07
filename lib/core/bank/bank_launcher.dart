import 'package:tiyn_app/core/bank/bank.dart';

enum BankLaunchResult {
  /// The bank app was started.
  opened,

  /// It is not installed; its store page was opened instead.
  storeOpened,

  /// Neither the app nor a store page could be opened.
  unavailable,
}

/// Opens a bank app. It never completes a payout: the parent confirms
/// separately, after coming back.
abstract interface class BankLauncher {
  Future<BankLaunchResult> open(Bank bank);
}
