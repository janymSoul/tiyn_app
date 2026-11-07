import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';

class FakeBankLauncher implements BankLauncher {
  FakeBankLauncher([this.result = BankLaunchResult.opened]);

  BankLaunchResult result;
  final opened = <Bank>[];

  @override
  Future<BankLaunchResult> open(Bank bank) async {
    opened.add(bank);
    return result;
  }
}
