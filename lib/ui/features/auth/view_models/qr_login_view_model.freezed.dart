// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_login_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrLoginState {

 QrPhase get phase; QrChallenge? get challenge; int get remainingSeconds; bool get polling; int get failures; int get effectId; AppFailure? get failure;
/// Create a copy of QrLoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrLoginStateCopyWith<QrLoginState> get copyWith => _$QrLoginStateCopyWithImpl<QrLoginState>(this as QrLoginState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QrLoginState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrLoginState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.challenge, _this.challenge) || other.challenge == _this.challenge)&&(identical(other.remainingSeconds, _this.remainingSeconds) || other.remainingSeconds == _this.remainingSeconds)&&(identical(other.polling, _this.polling) || other.polling == _this.polling)&&(identical(other.failures, _this.failures) || other.failures == _this.failures)&&(identical(other.effectId, _this.effectId) || other.effectId == _this.effectId)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as QrLoginState;
  return Object.hash(runtimeType,_this.phase,_this.challenge,_this.remainingSeconds,_this.polling,_this.failures,_this.effectId,_this.failure);
}

@override
String toString() {
  final _this = this as QrLoginState;
  return 'QrLoginState(phase: ${_this.phase}, challenge: ${_this.challenge}, remainingSeconds: ${_this.remainingSeconds}, polling: ${_this.polling}, failures: ${_this.failures}, effectId: ${_this.effectId}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $QrLoginStateCopyWith<$Res>  {
  factory $QrLoginStateCopyWith(QrLoginState value, $Res Function(QrLoginState) _then) = _$QrLoginStateCopyWithImpl;
@useResult
$Res call({
 QrPhase phase, QrChallenge? challenge, int remainingSeconds, bool polling, int failures, int effectId, AppFailure? failure
});




}
/// @nodoc
class _$QrLoginStateCopyWithImpl<$Res>
    implements $QrLoginStateCopyWith<$Res> {
  _$QrLoginStateCopyWithImpl(this._self, this._then);

  final QrLoginState _self;
  final $Res Function(QrLoginState) _then;

/// Create a copy of QrLoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? challenge = freezed,Object? remainingSeconds = null,Object? polling = null,Object? failures = null,Object? effectId = null,Object? failure = freezed,}) {
  return _then(QrLoginState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as QrPhase,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as QrChallenge?,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,polling: null == polling ? _self.polling : polling // ignore: cast_nullable_to_non_nullable
as bool,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as int,effectId: null == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [QrLoginState].
extension QrLoginStatePatterns on QrLoginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrLoginState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrLoginState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrLoginState value)  $default,){
final _that = this;
switch (_that) {
case _QrLoginState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrLoginState value)?  $default,){
final _that = this;
switch (_that) {
case _QrLoginState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QrPhase phase,  QrChallenge? challenge,  int remainingSeconds,  bool polling,  int failures,  int effectId,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrLoginState() when $default != null:
return $default(_that.phase,_that.challenge,_that.remainingSeconds,_that.polling,_that.failures,_that.effectId,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QrPhase phase,  QrChallenge? challenge,  int remainingSeconds,  bool polling,  int failures,  int effectId,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _QrLoginState():
return $default(_that.phase,_that.challenge,_that.remainingSeconds,_that.polling,_that.failures,_that.effectId,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QrPhase phase,  QrChallenge? challenge,  int remainingSeconds,  bool polling,  int failures,  int effectId,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _QrLoginState() when $default != null:
return $default(_that.phase,_that.challenge,_that.remainingSeconds,_that.polling,_that.failures,_that.effectId,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _QrLoginState implements QrLoginState {
  const _QrLoginState({this.phase = QrPhase.idle, this.challenge, this.remainingSeconds = 0, this.polling = false, this.failures = 0, this.effectId = 0, this.failure});
  

@override@JsonKey() final  QrPhase phase;
@override final  QrChallenge? challenge;
@override@JsonKey() final  int remainingSeconds;
@override@JsonKey() final  bool polling;
@override@JsonKey() final  int failures;
@override@JsonKey() final  int effectId;
@override final  AppFailure? failure;

/// Create a copy of QrLoginState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrLoginStateCopyWith<_QrLoginState> get copyWith => __$QrLoginStateCopyWithImpl<_QrLoginState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrLoginState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.polling, polling) || other.polling == polling)&&(identical(other.failures, failures) || other.failures == failures)&&(identical(other.effectId, effectId) || other.effectId == effectId)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,challenge,remainingSeconds,polling,failures,effectId,failure);
}

@override
String toString() {
    return 'QrLoginState(phase: $phase, challenge: $challenge, remainingSeconds: $remainingSeconds, polling: $polling, failures: $failures, effectId: $effectId, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$QrLoginStateCopyWith<$Res> implements $QrLoginStateCopyWith<$Res> {
  factory _$QrLoginStateCopyWith(_QrLoginState value, $Res Function(_QrLoginState) _then) = __$QrLoginStateCopyWithImpl;
@override @useResult
$Res call({
 QrPhase phase, QrChallenge? challenge, int remainingSeconds, bool polling, int failures, int effectId, AppFailure? failure
});




}
/// @nodoc
class __$QrLoginStateCopyWithImpl<$Res>
    implements _$QrLoginStateCopyWith<$Res> {
  __$QrLoginStateCopyWithImpl(this._self, this._then);

  final _QrLoginState _self;
  final $Res Function(_QrLoginState) _then;

/// Create a copy of QrLoginState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? challenge = freezed,Object? remainingSeconds = null,Object? polling = null,Object? failures = null,Object? effectId = null,Object? failure = freezed,}) {
  return _then(_QrLoginState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as QrPhase,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as QrChallenge?,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,polling: null == polling ? _self.polling : polling // ignore: cast_nullable_to_non_nullable
as bool,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as int,effectId: null == effectId ? _self.effectId : effectId // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
