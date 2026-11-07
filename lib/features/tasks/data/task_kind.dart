import 'package:tiyn_app/core/network/api_exception.dart';

enum TaskKind {
  task('TASK'),
  milestone('MILESTONE');

  const TaskKind(this.wire);

  final String wire;

  static TaskKind fromWire(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    throw const ApiException(code: 'invalid_response');
  }
}
