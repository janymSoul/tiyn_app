import 'package:flutter/foundation.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/tasks/data/task.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';

enum TeenStatusKind { toCheck, active, idle }

@immutable
class TeenStatus {
  const TeenStatus(this.kind, [this.count = 0]);

  final TeenStatusKind kind;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is TeenStatus && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);

  @override
  String toString() => 'TeenStatus($kind, $count)';
}

/// The status line of one teen, in priority order: anything `SUBMITTED` is
/// "N to check", else open work is "N active", else idle.
///
/// [submitted] and [assigned] are the two filtered lists (never the full
/// history), and may contain other teens' tasks.
///
/// "Active" counts the tasks to do. A milestone is only counted when it has no
/// open step of its own, so a milestone with 3 open steps is "3 active", not 4,
/// while a milestone whose steps are all approved (waiting for the teen to
/// submit it) is still work to do.
TeenStatus teenStatus(
  String teenId, {
  required Iterable<Task> submitted,
  required Iterable<Task> assigned,
}) {
  final toCheck = submitted.where((t) => t.teenId == teenId).length;
  if (toCheck > 0) return TeenStatus(TeenStatusKind.toCheck, toCheck);

  final open = assigned.where((t) => t.teenId == teenId).toList();
  final steps = open.where((t) => t.kind == TaskKind.task).length;
  final count = steps > 0 ? steps : open.length;
  return count > 0
      ? TeenStatus(TeenStatusKind.active, count)
      : const TeenStatus(TeenStatusKind.idle);
}

@immutable
class TeenOverview {
  const TeenOverview(this.teen, this.status);

  final FamilyMember teen;

  /// Null while the task lists are not loaded (or failed to load).
  final TeenStatus? status;
}

/// The rows of the parent home: teens with something to check first, then by
/// name. [submitted] and [assigned] are null until both are loaded; the rows
/// are then sorted by name only.
List<TeenOverview> teenOverview(
  Iterable<FamilyMember> teens, {
  required List<Task>? submitted,
  required List<Task>? assigned,
}) {
  final loaded = submitted != null && assigned != null;
  final rows = [
    for (final teen in teens)
      TeenOverview(
        teen,
        loaded
            ? teenStatus(teen.id, submitted: submitted, assigned: assigned)
            : null,
      ),
  ];
  int byName(TeenOverview a, TeenOverview b) {
    final byText = a.teen.displayName.toLowerCase().compareTo(
      b.teen.displayName.toLowerCase(),
    );
    return byText != 0 ? byText : a.teen.id.compareTo(b.teen.id);
  }

  bool needsCheck(TeenOverview row) =>
      row.status?.kind == TeenStatusKind.toCheck;

  rows.sort((a, b) {
    if (needsCheck(a) != needsCheck(b)) return needsCheck(a) ? -1 : 1;
    return byName(a, b);
  });
  return rows;
}
