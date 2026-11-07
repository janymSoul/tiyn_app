import 'package:tiyn_app/core/network/api_exception.dart';

enum TaskState {
  assigned('ASSIGNED'),
  submitted('SUBMITTED'),
  approved('APPROVED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const TaskState(this.wire);

  final String wire;

  /// An unknown value is a contract break, not something to guess a colour for.
  static TaskState fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    throw const ApiException(code: 'invalid_response');
  }

  /// Still waiting for the teen or the parent to do something.
  bool get isOpen => this == assigned || this == submitted;

  /// The parent can still call it off. Same states as `isOpen`; kept apart
  /// because they are different rules that happen to agree today.
  bool get canCancel => this == assigned || this == submitted;
}
