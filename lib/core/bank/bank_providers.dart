import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';
import 'package:tiyn_app/core/bank/no_bank_launcher.dart';

final bankLauncherProvider = Provider<BankLauncher>(
  (_) => const NoBankLauncher(),
);

/// The banks the parent can pick from. One bank: a single button; several: a
/// short list in this order.
final banksProvider = Provider<List<Bank>>((_) => supportedBanks);
