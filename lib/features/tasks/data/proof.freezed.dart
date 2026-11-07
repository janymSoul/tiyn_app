// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proof.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Proof {

 int get attemptNo; String? get imageUrl; String? get text; DateTime get createdAt;
/// Create a copy of Proof
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofCopyWith<Proof> get copyWith => _$ProofCopyWithImpl<Proof>(this as Proof, _$identity);

  /// Serializes this Proof to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Proof;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Proof&&(identical(other.attemptNo, _this.attemptNo) || other.attemptNo == _this.attemptNo)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Proof;
  return Object.hash(runtimeType,_this.attemptNo,_this.imageUrl,_this.text,_this.createdAt);
}

@override
String toString() {
  final _this = this as Proof;
  return 'Proof(attemptNo: ${_this.attemptNo}, imageUrl: ${_this.imageUrl}, text: ${_this.text}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ProofCopyWith<$Res>  {
  factory $ProofCopyWith(Proof value, $Res Function(Proof) _then) = _$ProofCopyWithImpl;
@useResult
$Res call({
 int attemptNo, String? imageUrl, String? text, DateTime createdAt
});




}
/// @nodoc
class _$ProofCopyWithImpl<$Res>
    implements $ProofCopyWith<$Res> {
  _$ProofCopyWithImpl(this._self, this._then);

  final Proof _self;
  final $Res Function(Proof) _then;

/// Create a copy of Proof
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attemptNo = null,Object? imageUrl = freezed,Object? text = freezed,Object? createdAt = null,}) {
  return _then(Proof(
attemptNo: null == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Proof].
extension ProofPatterns on Proof {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Proof value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Proof() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Proof value)  $default,){
final _that = this;
switch (_that) {
case _Proof():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Proof value)?  $default,){
final _that = this;
switch (_that) {
case _Proof() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int attemptNo,  String? imageUrl,  String? text,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Proof() when $default != null:
return $default(_that.attemptNo,_that.imageUrl,_that.text,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int attemptNo,  String? imageUrl,  String? text,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Proof():
return $default(_that.attemptNo,_that.imageUrl,_that.text,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int attemptNo,  String? imageUrl,  String? text,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Proof() when $default != null:
return $default(_that.attemptNo,_that.imageUrl,_that.text,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Proof implements Proof {
  const _Proof({required this.attemptNo, this.imageUrl, this.text, required this.createdAt});
  factory _Proof.fromJson(Map<String, dynamic> json) => _$ProofFromJson(json);

@override final  int attemptNo;
@override final  String? imageUrl;
@override final  String? text;
@override final  DateTime createdAt;

/// Create a copy of Proof
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProofCopyWith<_Proof> get copyWith => __$ProofCopyWithImpl<_Proof>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProofToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Proof&&(identical(other.attemptNo, attemptNo) || other.attemptNo == attemptNo)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,attemptNo,imageUrl,text,createdAt);
}

@override
String toString() {
    return 'Proof(attemptNo: $attemptNo, imageUrl: $imageUrl, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProofCopyWith<$Res> implements $ProofCopyWith<$Res> {
  factory _$ProofCopyWith(_Proof value, $Res Function(_Proof) _then) = __$ProofCopyWithImpl;
@override @useResult
$Res call({
 int attemptNo, String? imageUrl, String? text, DateTime createdAt
});




}
/// @nodoc
class __$ProofCopyWithImpl<$Res>
    implements _$ProofCopyWith<$Res> {
  __$ProofCopyWithImpl(this._self, this._then);

  final _Proof _self;
  final $Res Function(_Proof) _then;

/// Create a copy of Proof
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attemptNo = null,Object? imageUrl = freezed,Object? text = freezed,Object? createdAt = null,}) {
  return _then(_Proof(
attemptNo: null == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
