import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/bank/bank.dart';
import 'package:tiyn_app/core/bank/bank_launcher.dart';
import 'package:tiyn_app/core/bank/method_channel_bank_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MethodChannelBankLauncher.channelName);
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall) handler) {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler(call);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends the package of the bank', () async {
    answer((_) async => 'opened');
    await const MethodChannelBankLauncher().open(freedomBank);
    expect(calls.single.method, 'open');
    expect(calls.single.arguments, {'package': 'ffinbank.MyFreedom'});
  });

  test('maps the three answers', () async {
    for (final (answer_, expected) in [
      ('opened', BankLaunchResult.opened),
      ('store', BankLaunchResult.storeOpened),
      ('unavailable', BankLaunchResult.unavailable),
      ('something new', BankLaunchResult.unavailable),
    ]) {
      answer((_) async => answer_);
      expect(
        await const MethodChannelBankLauncher().open(freedomBank),
        expected,
        reason: answer_,
      );
    }
  });

  test('a null answer is unavailable', () async {
    answer((_) async => null);
    expect(
      await const MethodChannelBankLauncher().open(freedomBank),
      BankLaunchResult.unavailable,
    );
  });

  test('a platform error is unavailable, never thrown', () async {
    answer((_) async => throw PlatformException(code: 'boom'));
    expect(
      await const MethodChannelBankLauncher().open(freedomBank),
      BankLaunchResult.unavailable,
    );
  });

  test('a missing channel (a platform without it) is unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(
      await const MethodChannelBankLauncher().open(freedomBank),
      BankLaunchResult.unavailable,
    );
  });
}
