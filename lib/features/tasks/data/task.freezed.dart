// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

 String get id; String get teenId; String get parentId; TaskKind get kind; String get title; String get description; Money get reward; Money get penalty; TaskState get state; DateTime get deadlineAt; DateTime? get submittedAt; DateTime? get decidedAt; String? get decisionNote; String? get milestoneId; int? get approvedTasks; int? get totalTasks;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Task;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teenId, _this.teenId) || other.teenId == _this.teenId)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.reward, _this.reward) || other.reward == _this.reward)&&(identical(other.penalty, _this.penalty) || other.penalty == _this.penalty)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.deadlineAt, _this.deadlineAt) || other.deadlineAt == _this.deadlineAt)&&(identical(other.submittedAt, _this.submittedAt) || other.submittedAt == _this.submittedAt)&&(identical(other.decidedAt, _this.decidedAt) || other.decidedAt == _this.decidedAt)&&(identical(other.decisionNote, _this.decisionNote) || other.decisionNote == _this.decisionNote)&&(identical(other.milestoneId, _this.milestoneId) || other.milestoneId == _this.milestoneId)&&(identical(other.approvedTasks, _this.approvedTasks) || other.approvedTasks == _this.approvedTasks)&&(identical(other.totalTasks, _this.totalTasks) || other.totalTasks == _this.totalTasks));
}


@override
int get hashCode {
  final _this = this as Task;
  return Object.hash(runtimeType,_this.id,_this.teenId,_this.parentId,_this.kind,_this.title,_this.description,_this.reward,_this.penalty,_this.state,_this.deadlineAt,_this.submittedAt,_this.decidedAt,_this.decisionNote,_this.milestoneId,_this.approvedTasks,_this.totalTasks);
}

@override
String toString() {
  final _this = this as Task;
  return 'Task(id: ${_this.id}, teenId: ${_this.teenId}, parentId: ${_this.parentId}, kind: ${_this.kind}, title: ${_this.title}, description: ${_this.description}, reward: ${_this.reward}, penalty: ${_this.penalty}, state: ${_this.state}, deadlineAt: ${_this.deadlineAt}, submittedAt: ${_this.submittedAt}, decidedAt: ${_this.decidedAt}, decisionNote: ${_this.decisionNote}, milestoneId: ${_this.milestoneId}, approvedTasks: ${_this.approvedTasks}, totalTasks: ${_this.totalTasks})';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String teenId, String parentId, TaskKind kind, String title, String description, Money reward, Money penalty, TaskState state, DateTime deadlineAt, DateTime? submittedAt, DateTime? decidedAt, String? decisionNote, String? milestoneId, int? approvedTasks, int? totalTasks
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teenId = null,Object? parentId = null,Object? kind = null,Object? title = null,Object? description = null,Object? reward = null,Object? penalty = null,Object? state = null,Object? deadlineAt = null,Object? submittedAt = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? milestoneId = freezed,Object? approvedTasks = freezed,Object? totalTasks = freezed,}) {
  return _then(Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teenId: null == teenId ? _self.teenId : teenId // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as Money,penalty: null == penalty ? _self.penalty : penalty // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,milestoneId: freezed == milestoneId ? _self.milestoneId : milestoneId // ignore: cast_nullable_to_non_nullable
as String?,approvedTasks: freezed == approvedTasks ? _self.approvedTasks : approvedTasks // ignore: cast_nullable_to_non_nullable
as int?,totalTasks: freezed == totalTasks ? _self.totalTasks : totalTasks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String teenId,  String parentId,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  DateTime? submittedAt,  DateTime? decidedAt,  String? decisionNote,  String? milestoneId,  int? approvedTasks,  int? totalTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.teenId,_that.parentId,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.submittedAt,_that.decidedAt,_that.decisionNote,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String teenId,  String parentId,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  DateTime? submittedAt,  DateTime? decidedAt,  String? decisionNote,  String? milestoneId,  int? approvedTasks,  int? totalTasks)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.teenId,_that.parentId,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.submittedAt,_that.decidedAt,_that.decisionNote,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String teenId,  String parentId,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  DateTime? submittedAt,  DateTime? decidedAt,  String? decisionNote,  String? milestoneId,  int? approvedTasks,  int? totalTasks)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.teenId,_that.parentId,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.submittedAt,_that.decidedAt,_that.decisionNote,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.teenId, required this.parentId, required this.kind, required this.title, this.description = '', required this.reward, required this.penalty, required this.state, required this.deadlineAt, this.submittedAt, this.decidedAt, this.decisionNote, this.milestoneId, this.approvedTasks, this.totalTasks});
  

@override final  String id;
@override final  String teenId;
@override final  String parentId;
@override final  TaskKind kind;
@override final  String title;
@override@JsonKey() final  String description;
@override final  Money reward;
@override final  Money penalty;
@override final  TaskState state;
@override final  DateTime deadlineAt;
@override final  DateTime? submittedAt;
@override final  DateTime? decidedAt;
@override final  String? decisionNote;
@override final  String? milestoneId;
@override final  int? approvedTasks;
@override final  int? totalTasks;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.teenId, teenId) || other.teenId == teenId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.reward, reward) || other.reward == reward)&&(identical(other.penalty, penalty) || other.penalty == penalty)&&(identical(other.state, state) || other.state == state)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote)&&(identical(other.milestoneId, milestoneId) || other.milestoneId == milestoneId)&&(identical(other.approvedTasks, approvedTasks) || other.approvedTasks == approvedTasks)&&(identical(other.totalTasks, totalTasks) || other.totalTasks == totalTasks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,teenId,parentId,kind,title,description,reward,penalty,state,deadlineAt,submittedAt,decidedAt,decisionNote,milestoneId,approvedTasks,totalTasks);
}

@override
String toString() {
    return 'Task(id: $id, teenId: $teenId, parentId: $parentId, kind: $kind, title: $title, description: $description, reward: $reward, penalty: $penalty, state: $state, deadlineAt: $deadlineAt, submittedAt: $submittedAt, decidedAt: $decidedAt, decisionNote: $decisionNote, milestoneId: $milestoneId, approvedTasks: $approvedTasks, totalTasks: $totalTasks)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String teenId, String parentId, TaskKind kind, String title, String description, Money reward, Money penalty, TaskState state, DateTime deadlineAt, DateTime? submittedAt, DateTime? decidedAt, String? decisionNote, String? milestoneId, int? approvedTasks, int? totalTasks
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teenId = null,Object? parentId = null,Object? kind = null,Object? title = null,Object? description = null,Object? reward = null,Object? penalty = null,Object? state = null,Object? deadlineAt = null,Object? submittedAt = freezed,Object? decidedAt = freezed,Object? decisionNote = freezed,Object? milestoneId = freezed,Object? approvedTasks = freezed,Object? totalTasks = freezed,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teenId: null == teenId ? _self.teenId : teenId // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as Money,penalty: null == penalty ? _self.penalty : penalty // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,milestoneId: freezed == milestoneId ? _self.milestoneId : milestoneId // ignore: cast_nullable_to_non_nullable
as String?,approvedTasks: freezed == approvedTasks ? _self.approvedTasks : approvedTasks // ignore: cast_nullable_to_non_nullable
as int?,totalTasks: freezed == totalTasks ? _self.totalTasks : totalTasks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
