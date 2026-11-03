import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void expired() => state++;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);
