// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Payout {

 String get id; String get teenId; String get parentId; Money get amount; PayoutState get state; DateTime get requestedAt; DateTime? get expiresAt; DateTime? get resolvedAt; CancelReason? get cancelReason;
/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutCopyWith<Payout> get copyWith => _$PayoutCopyWithImpl<Payout>(this as Payout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Payout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payout&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teenId, _this.teenId) || other.teenId == _this.teenId)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.requestedAt, _this.requestedAt) || other.requestedAt == _this.requestedAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.cancelReason, _this.cancelReason) || other.cancelReason == _this.cancelReason));
}


@override
int get hashCode {
  final _this = this as Payout;
  return Object.hash(runtimeType,_this.id,_this.teenId,_this.parentId,_this.amount,_this.state,_this.requestedAt,_this.expiresAt,_this.resolvedAt,_this.cancelReason);
}

@override
String toString() {
  final _this = this as Payout;
  return 'Payout(id: ${_this.id}, teenId: ${_this.teenId}, parentId: ${_this.parentId}, amount: ${_this.amount}, state: ${_this.state}, requestedAt: ${_this.requestedAt}, expiresAt: ${_this.expiresAt}, resolvedAt: ${_this.resolvedAt}, cancelReason: ${_this.cancelReason})';
}


}

/// @nodoc
abstract mixin class $PayoutCopyWith<$Res>  {
  factory $PayoutCopyWith(Payout value, $Res Function(Payout) _then) = _$PayoutCopyWithImpl;
@useResult
$Res call({
 String id, String teenId, String parentId, Money amount, PayoutState state, DateTime requestedAt, DateTime? expiresAt, DateTime? resolvedAt, CancelReason? cancelReason
});




}
/// @nodoc
class _$PayoutCopyWithImpl<$Res>
    implements $PayoutCopyWith<$Res> {
  _$PayoutCopyWithImpl(this._self, this._then);

  final Payout _self;
  final $Res Function(Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teenId = null,Object? parentId = null,Object? amount = null,Object? state = null,Object? requestedAt = null,Object? expiresAt = freezed,Object? resolvedAt = freezed,Object? cancelReason = freezed,}) {
  return _then(Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teenId: null == teenId ? _self.teenId : teenId // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PayoutState,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as CancelReason?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payout].
extension PayoutPatterns on Payout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payout value)  $default,){
final _that = this;
switch (_that) {
case _Payout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payout value)?  $default,){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String teenId,  String parentId,  Money amount,  PayoutState state,  DateTime requestedAt,  DateTime? expiresAt,  DateTime? resolvedAt,  CancelReason? cancelReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.teenId,_that.parentId,_that.amount,_that.state,_that.requestedAt,_that.expiresAt,_that.resolvedAt,_that.cancelReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String teenId,  String parentId,  Money amount,  PayoutState state,  DateTime requestedAt,  DateTime? expiresAt,  DateTime? resolvedAt,  CancelReason? cancelReason)  $default,) {final _that = this;
switch (_that) {
case _Payout():
return $default(_that.id,_that.teenId,_that.parentId,_that.amount,_that.state,_that.requestedAt,_that.expiresAt,_that.resolvedAt,_that.cancelReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String teenId,  String parentId,  Money amount,  PayoutState state,  DateTime requestedAt,  DateTime? expiresAt,  DateTime? resolvedAt,  CancelReason? cancelReason)?  $default,) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.teenId,_that.parentId,_that.amount,_that.state,_that.requestedAt,_that.expiresAt,_that.resolvedAt,_that.cancelReason);case _:
  return null;

}
}

}

/// @nodoc


class _Payout implements Payout {
  const _Payout({required this.id, required this.teenId, required this.parentId, required this.amount, required this.state, required this.requestedAt, this.expiresAt, this.resolvedAt, this.cancelReason});
  

@override final  String id;
@override final  String teenId;
@override final  String parentId;
@override final  Money amount;
@override final  PayoutState state;
@override final  DateTime requestedAt;
@override final  DateTime? expiresAt;
@override final  DateTime? resolvedAt;
@override final  CancelReason? cancelReason;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutCopyWith<_Payout> get copyWith => __$PayoutCopyWithImpl<_Payout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payout&&(identical(other.id, id) || other.id == id)&&(identical(other.teenId, teenId) || other.teenId == teenId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.state, state) || other.state == state)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,teenId,parentId,amount,state,requestedAt,expiresAt,resolvedAt,cancelReason);
}

@override
String toString() {
    return 'Payout(id: $id, teenId: $teenId, parentId: $parentId, amount: $amount, state: $state, requestedAt: $requestedAt, expiresAt: $expiresAt, resolvedAt: $resolvedAt, cancelReason: $cancelReason)';
}


}

/// @nodoc
abstract mixin class _$PayoutCopyWith<$Res> implements $PayoutCopyWith<$Res> {
  factory _$PayoutCopyWith(_Payout value, $Res Function(_Payout) _then) = __$PayoutCopyWithImpl;
@override @useResult
$Res call({
 String id, String teenId, String parentId, Money amount, PayoutState state, DateTime requestedAt, DateTime? expiresAt, DateTime? resolvedAt, CancelReason? cancelReason
});




}
/// @nodoc
class __$PayoutCopyWithImpl<$Res>
    implements _$PayoutCopyWith<$Res> {
  __$PayoutCopyWithImpl(this._self, this._then);

  final _Payout _self;
  final $Res Function(_Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teenId = null,Object? parentId = null,Object? amount = null,Object? state = null,Object? requestedAt = null,Object? expiresAt = freezed,Object? resolvedAt = freezed,Object? cancelReason = freezed,}) {
  return _then(_Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teenId: null == teenId ? _self.teenId : teenId // ignore: cast_nullable_to_non_nullable
as String,parentId: null == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PayoutState,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as CancelReason?,
  ));
}


}

// dart format on
