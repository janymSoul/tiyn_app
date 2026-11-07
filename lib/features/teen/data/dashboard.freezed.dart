// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DashboardTask {

 String get id; TaskKind get kind; String get title; String get description; Money get reward; Money get penalty; TaskState get state; DateTime get deadlineAt; String? get milestoneId; int? get approvedTasks; int? get totalTasks;
/// Create a copy of DashboardTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardTaskCopyWith<DashboardTask> get copyWith => _$DashboardTaskCopyWithImpl<DashboardTask>(this as DashboardTask, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DashboardTask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardTask&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.reward, _this.reward) || other.reward == _this.reward)&&(identical(other.penalty, _this.penalty) || other.penalty == _this.penalty)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.deadlineAt, _this.deadlineAt) || other.deadlineAt == _this.deadlineAt)&&(identical(other.milestoneId, _this.milestoneId) || other.milestoneId == _this.milestoneId)&&(identical(other.approvedTasks, _this.approvedTasks) || other.approvedTasks == _this.approvedTasks)&&(identical(other.totalTasks, _this.totalTasks) || other.totalTasks == _this.totalTasks));
}


@override
int get hashCode {
  final _this = this as DashboardTask;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.title,_this.description,_this.reward,_this.penalty,_this.state,_this.deadlineAt,_this.milestoneId,_this.approvedTasks,_this.totalTasks);
}

@override
String toString() {
  final _this = this as DashboardTask;
  return 'DashboardTask(id: ${_this.id}, kind: ${_this.kind}, title: ${_this.title}, description: ${_this.description}, reward: ${_this.reward}, penalty: ${_this.penalty}, state: ${_this.state}, deadlineAt: ${_this.deadlineAt}, milestoneId: ${_this.milestoneId}, approvedTasks: ${_this.approvedTasks}, totalTasks: ${_this.totalTasks})';
}


}

/// @nodoc
abstract mixin class $DashboardTaskCopyWith<$Res>  {
  factory $DashboardTaskCopyWith(DashboardTask value, $Res Function(DashboardTask) _then) = _$DashboardTaskCopyWithImpl;
@useResult
$Res call({
 String id, TaskKind kind, String title, String description, Money reward, Money penalty, TaskState state, DateTime deadlineAt, String? milestoneId, int? approvedTasks, int? totalTasks
});




}
/// @nodoc
class _$DashboardTaskCopyWithImpl<$Res>
    implements $DashboardTaskCopyWith<$Res> {
  _$DashboardTaskCopyWithImpl(this._self, this._then);

  final DashboardTask _self;
  final $Res Function(DashboardTask) _then;

/// Create a copy of DashboardTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? description = null,Object? reward = null,Object? penalty = null,Object? state = null,Object? deadlineAt = null,Object? milestoneId = freezed,Object? approvedTasks = freezed,Object? totalTasks = freezed,}) {
  return _then(DashboardTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as Money,penalty: null == penalty ? _self.penalty : penalty // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime,milestoneId: freezed == milestoneId ? _self.milestoneId : milestoneId // ignore: cast_nullable_to_non_nullable
as String?,approvedTasks: freezed == approvedTasks ? _self.approvedTasks : approvedTasks // ignore: cast_nullable_to_non_nullable
as int?,totalTasks: freezed == totalTasks ? _self.totalTasks : totalTasks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardTask].
extension DashboardTaskPatterns on DashboardTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardTask value)  $default,){
final _that = this;
switch (_that) {
case _DashboardTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardTask value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  String? milestoneId,  int? approvedTasks,  int? totalTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardTask() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  String? milestoneId,  int? approvedTasks,  int? totalTasks)  $default,) {final _that = this;
switch (_that) {
case _DashboardTask():
return $default(_that.id,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TaskKind kind,  String title,  String description,  Money reward,  Money penalty,  TaskState state,  DateTime deadlineAt,  String? milestoneId,  int? approvedTasks,  int? totalTasks)?  $default,) {final _that = this;
switch (_that) {
case _DashboardTask() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.description,_that.reward,_that.penalty,_that.state,_that.deadlineAt,_that.milestoneId,_that.approvedTasks,_that.totalTasks);case _:
  return null;

}
}

}

/// @nodoc


class _DashboardTask implements DashboardTask {
  const _DashboardTask({required this.id, required this.kind, required this.title, this.description = '', required this.reward, required this.penalty, required this.state, required this.deadlineAt, this.milestoneId, this.approvedTasks, this.totalTasks});
  

@override final  String id;
@override final  TaskKind kind;
@override final  String title;
@override@JsonKey() final  String description;
@override final  Money reward;
@override final  Money penalty;
@override final  TaskState state;
@override final  DateTime deadlineAt;
@override final  String? milestoneId;
@override final  int? approvedTasks;
@override final  int? totalTasks;

/// Create a copy of DashboardTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardTaskCopyWith<_DashboardTask> get copyWith => __$DashboardTaskCopyWithImpl<_DashboardTask>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardTask&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.reward, reward) || other.reward == reward)&&(identical(other.penalty, penalty) || other.penalty == penalty)&&(identical(other.state, state) || other.state == state)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.milestoneId, milestoneId) || other.milestoneId == milestoneId)&&(identical(other.approvedTasks, approvedTasks) || other.approvedTasks == approvedTasks)&&(identical(other.totalTasks, totalTasks) || other.totalTasks == totalTasks));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,title,description,reward,penalty,state,deadlineAt,milestoneId,approvedTasks,totalTasks);
}

@override
String toString() {
    return 'DashboardTask(id: $id, kind: $kind, title: $title, description: $description, reward: $reward, penalty: $penalty, state: $state, deadlineAt: $deadlineAt, milestoneId: $milestoneId, approvedTasks: $approvedTasks, totalTasks: $totalTasks)';
}


}

/// @nodoc
abstract mixin class _$DashboardTaskCopyWith<$Res> implements $DashboardTaskCopyWith<$Res> {
  factory _$DashboardTaskCopyWith(_DashboardTask value, $Res Function(_DashboardTask) _then) = __$DashboardTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, TaskKind kind, String title, String description, Money reward, Money penalty, TaskState state, DateTime deadlineAt, String? milestoneId, int? approvedTasks, int? totalTasks
});




}
/// @nodoc
class __$DashboardTaskCopyWithImpl<$Res>
    implements _$DashboardTaskCopyWith<$Res> {
  __$DashboardTaskCopyWithImpl(this._self, this._then);

  final _DashboardTask _self;
  final $Res Function(_DashboardTask) _then;

/// Create a copy of DashboardTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? description = null,Object? reward = null,Object? penalty = null,Object? state = null,Object? deadlineAt = null,Object? milestoneId = freezed,Object? approvedTasks = freezed,Object? totalTasks = freezed,}) {
  return _then(_DashboardTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TaskKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reward: null == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as Money,penalty: null == penalty ? _self.penalty : penalty // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TaskState,deadlineAt: null == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime,milestoneId: freezed == milestoneId ? _self.milestoneId : milestoneId // ignore: cast_nullable_to_non_nullable
as String?,approvedTasks: freezed == approvedTasks ? _self.approvedTasks : approvedTasks // ignore: cast_nullable_to_non_nullable
as int?,totalTasks: freezed == totalTasks ? _self.totalTasks : totalTasks // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$Balance {

 Money get balance; Money get locked; Money get available;
/// Create a copy of Balance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceCopyWith<Balance> get copyWith => _$BalanceCopyWithImpl<Balance>(this as Balance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Balance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Balance&&(identical(other.balance, _this.balance) || other.balance == _this.balance)&&(identical(other.locked, _this.locked) || other.locked == _this.locked)&&(identical(other.available, _this.available) || other.available == _this.available));
}


@override
int get hashCode {
  final _this = this as Balance;
  return Object.hash(runtimeType,_this.balance,_this.locked,_this.available);
}

@override
String toString() {
  final _this = this as Balance;
  return 'Balance(balance: ${_this.balance}, locked: ${_this.locked}, available: ${_this.available})';
}


}

/// @nodoc
abstract mixin class $BalanceCopyWith<$Res>  {
  factory $BalanceCopyWith(Balance value, $Res Function(Balance) _then) = _$BalanceCopyWithImpl;
@useResult
$Res call({
 Money balance, Money locked, Money available
});




}
/// @nodoc
class _$BalanceCopyWithImpl<$Res>
    implements $BalanceCopyWith<$Res> {
  _$BalanceCopyWithImpl(this._self, this._then);

  final Balance _self;
  final $Res Function(Balance) _then;

/// Create a copy of Balance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? locked = null,Object? available = null,}) {
  return _then(Balance(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as Money,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

}


/// Adds pattern-matching-related methods to [Balance].
extension BalancePatterns on Balance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Balance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Balance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Balance value)  $default,){
final _that = this;
switch (_that) {
case _Balance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Balance value)?  $default,){
final _that = this;
switch (_that) {
case _Balance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Money balance,  Money locked,  Money available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Balance() when $default != null:
return $default(_that.balance,_that.locked,_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Money balance,  Money locked,  Money available)  $default,) {final _that = this;
switch (_that) {
case _Balance():
return $default(_that.balance,_that.locked,_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Money balance,  Money locked,  Money available)?  $default,) {final _that = this;
switch (_that) {
case _Balance() when $default != null:
return $default(_that.balance,_that.locked,_that.available);case _:
  return null;

}
}

}

/// @nodoc


class _Balance implements Balance {
  const _Balance({required this.balance, required this.locked, required this.available});
  

@override final  Money balance;
@override final  Money locked;
@override final  Money available;

/// Create a copy of Balance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceCopyWith<_Balance> get copyWith => __$BalanceCopyWithImpl<_Balance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Balance&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.available, available) || other.available == available));
}


@override
int get hashCode {
    return Object.hash(runtimeType,balance,locked,available);
}

@override
String toString() {
    return 'Balance(balance: $balance, locked: $locked, available: $available)';
}


}

/// @nodoc
abstract mixin class _$BalanceCopyWith<$Res> implements $BalanceCopyWith<$Res> {
  factory _$BalanceCopyWith(_Balance value, $Res Function(_Balance) _then) = __$BalanceCopyWithImpl;
@override @useResult
$Res call({
 Money balance, Money locked, Money available
});




}
/// @nodoc
class __$BalanceCopyWithImpl<$Res>
    implements _$BalanceCopyWith<$Res> {
  __$BalanceCopyWithImpl(this._self, this._then);

  final _Balance _self;
  final $Res Function(_Balance) _then;

/// Create a copy of Balance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? locked = null,Object? available = null,}) {
  return _then(_Balance(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as Money,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}

/// @nodoc
mixin _$OpenPayout {

 String get id; String get parentId; Money get amount; DateTime get requestedAt; DateTime get expiresAt;
/// Create a copy of OpenPayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenPayoutCopyWith<OpenPayout> get copyWith => _$OpenPayoutCopyWithImpl<OpenPayout>(this as OpenPayout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OpenPayout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenPayout&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.requestedAt, _this.requestedAt) || other.requestedAt == _this.requestedAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}


@override
int get hashCode {
  final _this = this as OpenPayout;
  return Object.hash(runtimeType,_this.id,_this.parentId,_this.amount,_this.requestedAt,_this.expiresAt);
}

@override
String toString() {
  final _this = this as OpenPayout;
  return 'OpenPayout(id: ${_this.id}, parentId: ${_this.parentId}, amount: ${_this.amount}, requestedAt: ${_this.requestedAt}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $OpenPayoutCopyWith<$Res>  {
  factory $OpenPayoutCopyWith(OpenPayout value, $Res Function(OpenPayout) _then) = _$OpenPayoutCopyWithImpl;
@useResult
$Res call({
 String id, String parentId, Money amount, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class _$OpenPayoutCopyWithImpl<$Res>
    implements $OpenPayoutCopyWith<$Res> {
  _$OpenPayoutCopyWithImpl(this._self, this._then);

  final OpenPayout _self;
  final $Res Function(OpenPayout) _then;

/// Create a copy of OpenPayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = null,Object? amount = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(OpenPayout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenPayout].
extension OpenPayoutPatterns on OpenPayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenPayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenPayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenPayout value)  $default,){
final _that = this;
switch (_that) {
case _OpenPayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenPayout value)?  $default,){
final _that = this;
switch (_that) {
case _OpenPayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String parentId,  Money amount,  DateTime requestedAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenPayout() when $default != null:
return $default(_that.id,_that.parentId,_that.amount,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String parentId,  Money amount,  DateTime requestedAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _OpenPayout():
return $default(_that.id,_that.parentId,_that.amount,_that.requestedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String parentId,  Money amount,  DateTime requestedAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _OpenPayout() when $default != null:
return $default(_that.id,_that.parentId,_that.amount,_that.requestedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _OpenPayout implements OpenPayout {
  const _OpenPayout({required this.id, required this.parentId, required this.amount, required this.requestedAt, required this.expiresAt});
  

@override final  String id;
@override final  String parentId;
@override final  Money amount;
@override final  DateTime requestedAt;
@override final  DateTime expiresAt;

/// Create a copy of OpenPayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenPayoutCopyWith<_OpenPayout> get copyWith => __$OpenPayoutCopyWithImpl<_OpenPayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenPayout&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,parentId,amount,requestedAt,expiresAt);
}

@override
String toString() {
    return 'OpenPayout(id: $id, parentId: $parentId, amount: $amount, requestedAt: $requestedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$OpenPayoutCopyWith<$Res> implements $OpenPayoutCopyWith<$Res> {
  factory _$OpenPayoutCopyWith(_OpenPayout value, $Res Function(_OpenPayout) _then) = __$OpenPayoutCopyWithImpl;
@override @useResult
$Res call({
 String id, String parentId, Money amount, DateTime requestedAt, DateTime expiresAt
});




}
/// @nodoc
class __$OpenPayoutCopyWithImpl<$Res>
    implements _$OpenPayoutCopyWith<$Res> {
  __$OpenPayoutCopyWithImpl(this._self, this._then);

  final _OpenPayout _self;
  final $Res Function(_OpenPayout) _then;

/// Create a copy of OpenPayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = null,Object? amount = null,Object? requestedAt = null,Object? expiresAt = null,}) {
  return _then(_OpenPayout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$Dashboard {

 Balance get balance; Money get pending; List<DashboardTask> get chores; List<DashboardTask> get milestones; OpenPayout? get openPayout;
/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardCopyWith<Dashboard> get copyWith => _$DashboardCopyWithImpl<Dashboard>(this as Dashboard, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Dashboard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Dashboard&&(identical(other.balance, _this.balance) || other.balance == _this.balance)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&const DeepCollectionEquality().equals(other.chores, _this.chores)&&const DeepCollectionEquality().equals(other.milestones, _this.milestones)&&(identical(other.openPayout, _this.openPayout) || other.openPayout == _this.openPayout));
}


@override
int get hashCode {
  final _this = this as Dashboard;
  return Object.hash(runtimeType,_this.balance,_this.pending,const DeepCollectionEquality().hash(_this.chores),const DeepCollectionEquality().hash(_this.milestones),_this.openPayout);
}

@override
String toString() {
  final _this = this as Dashboard;
  return 'Dashboard(balance: ${_this.balance}, pending: ${_this.pending}, chores: ${_this.chores}, milestones: ${_this.milestones}, openPayout: ${_this.openPayout})';
}


}

/// @nodoc
abstract mixin class $DashboardCopyWith<$Res>  {
  factory $DashboardCopyWith(Dashboard value, $Res Function(Dashboard) _then) = _$DashboardCopyWithImpl;
@useResult
$Res call({
 Balance balance, Money pending, List<DashboardTask> chores, List<DashboardTask> milestones, OpenPayout? openPayout
});


$BalanceCopyWith<$Res> get balance;$OpenPayoutCopyWith<$Res>? get openPayout;

}
/// @nodoc
class _$DashboardCopyWithImpl<$Res>
    implements $DashboardCopyWith<$Res> {
  _$DashboardCopyWithImpl(this._self, this._then);

  final Dashboard _self;
  final $Res Function(Dashboard) _then;

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? pending = null,Object? chores = null,Object? milestones = null,Object? openPayout = freezed,}) {
  return _then(Dashboard(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Balance,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as Money,chores: null == chores ? _self.chores : chores // ignore: cast_nullable_to_non_nullable
as List<DashboardTask>,milestones: null == milestones ? _self.milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<DashboardTask>,openPayout: freezed == openPayout ? _self.openPayout : openPayout // ignore: cast_nullable_to_non_nullable
as OpenPayout?,
  ));
}
/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceCopyWith<$Res> get balance {
  
  return $BalanceCopyWith<$Res>(_self.balance, (value) {
    return _then(_self.copyWith(balance: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPayoutCopyWith<$Res>? get openPayout {
    if (_self.openPayout == null) {
    return null;
  }

  return $OpenPayoutCopyWith<$Res>(_self.openPayout!, (value) {
    return _then(_self.copyWith(openPayout: value));
  });
}
}


/// Adds pattern-matching-related methods to [Dashboard].
extension DashboardPatterns on Dashboard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Dashboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Dashboard value)  $default,){
final _that = this;
switch (_that) {
case _Dashboard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Dashboard value)?  $default,){
final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Balance balance,  Money pending,  List<DashboardTask> chores,  List<DashboardTask> milestones,  OpenPayout? openPayout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
return $default(_that.balance,_that.pending,_that.chores,_that.milestones,_that.openPayout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Balance balance,  Money pending,  List<DashboardTask> chores,  List<DashboardTask> milestones,  OpenPayout? openPayout)  $default,) {final _that = this;
switch (_that) {
case _Dashboard():
return $default(_that.balance,_that.pending,_that.chores,_that.milestones,_that.openPayout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Balance balance,  Money pending,  List<DashboardTask> chores,  List<DashboardTask> milestones,  OpenPayout? openPayout)?  $default,) {final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
return $default(_that.balance,_that.pending,_that.chores,_that.milestones,_that.openPayout);case _:
  return null;

}
}

}

/// @nodoc


class _Dashboard implements Dashboard {
  const _Dashboard({required this.balance, required this.pending, required  List<DashboardTask> chores, required  List<DashboardTask> milestones, this.openPayout}): _chores = chores,_milestones = milestones;
  

@override final  Balance balance;
@override final  Money pending;
 final  List<DashboardTask> _chores;
@override List<DashboardTask> get chores {
  if (_chores is EqualUnmodifiableListView) return _chores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chores);
}

 final  List<DashboardTask> _milestones;
@override List<DashboardTask> get milestones {
  if (_milestones is EqualUnmodifiableListView) return _milestones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_milestones);
}

@override final  OpenPayout? openPayout;

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardCopyWith<_Dashboard> get copyWith => __$DashboardCopyWithImpl<_Dashboard>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dashboard&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.pending, pending) || other.pending == pending)&&const DeepCollectionEquality().equals(other.chores, _chores)&&const DeepCollectionEquality().equals(other.milestones, _milestones)&&(identical(other.openPayout, openPayout) || other.openPayout == openPayout));
}


@override
int get hashCode {
    return Object.hash(runtimeType,balance,pending,const DeepCollectionEquality().hash(_chores),const DeepCollectionEquality().hash(_milestones),openPayout);
}

@override
String toString() {
    return 'Dashboard(balance: $balance, pending: $pending, chores: $chores, milestones: $milestones, openPayout: $openPayout)';
}


}

/// @nodoc
abstract mixin class _$DashboardCopyWith<$Res> implements $DashboardCopyWith<$Res> {
  factory _$DashboardCopyWith(_Dashboard value, $Res Function(_Dashboard) _then) = __$DashboardCopyWithImpl;
@override @useResult
$Res call({
 Balance balance, Money pending, List<DashboardTask> chores, List<DashboardTask> milestones, OpenPayout? openPayout
});


@override $BalanceCopyWith<$Res> get balance;@override $OpenPayoutCopyWith<$Res>? get openPayout;

}
/// @nodoc
class __$DashboardCopyWithImpl<$Res>
    implements _$DashboardCopyWith<$Res> {
  __$DashboardCopyWithImpl(this._self, this._then);

  final _Dashboard _self;
  final $Res Function(_Dashboard) _then;

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? pending = null,Object? chores = null,Object? milestones = null,Object? openPayout = freezed,}) {
  return _then(_Dashboard(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Balance,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as Money,chores: null == chores ? _self._chores : chores // ignore: cast_nullable_to_non_nullable
as List<DashboardTask>,milestones: null == milestones ? _self._milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<DashboardTask>,openPayout: freezed == openPayout ? _self.openPayout : openPayout // ignore: cast_nullable_to_non_nullable
as OpenPayout?,
  ));
}

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceCopyWith<$Res> get balance {
  
  return $BalanceCopyWith<$Res>(_self.balance, (value) {
    return _then(_self.copyWith(balance: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPayoutCopyWith<$Res>? get openPayout {
    if (_self.openPayout == null) {
    return null;
  }

  return $OpenPayoutCopyWith<$Res>(_self.openPayout!, (value) {
    return _then(_self.copyWith(openPayout: value));
  });
}
}

// dart format on
