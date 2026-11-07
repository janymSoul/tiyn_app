import 'package:tiyn_app/core/network/api_exception.dart';

enum PayoutState {
  requested('REQUESTED'),
  fulfilled('FULFILLED'),
  cancelled('CANCELLED');

  const PayoutState(this.wire);

  final String wire;

  /// An unknown value is a contract break, not something to guess a label for.
  static PayoutState fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    throw const ApiException(code: 'invalid_response');
  }

  bool get isOpen => this == requested;
}
