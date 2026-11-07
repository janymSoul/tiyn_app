import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';

/// The default: nothing is opened. Tests never touch the platform; `main`
/// wires the real launcher.
class NoBankLauncher implements BankLauncher {
  const NoBankLauncher();

  @override
  Future<BankLaunchResult> open(Bank bank) async =>
      BankLaunchResult.unavailable;
}
