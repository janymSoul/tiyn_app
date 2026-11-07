import 'package:tiyn_app/core/network/api_exception.dart';

enum CancelReason {
  teenCancelled('TEEN_CANCELLED'),
  declined('DECLINED'),
  expired('EXPIRED'),
  unlinked('UNLINKED');

  const CancelReason(this.wire);

  final String wire;

  static CancelReason fromWire(Object? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    throw const ApiException(code: 'invalid_response');
  }
}
