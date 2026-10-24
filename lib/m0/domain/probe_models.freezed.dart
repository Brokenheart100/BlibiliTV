// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'probe_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProbeCheck {

 String get capability; bool get passed; String get detail;
/// Create a copy of ProbeCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProbeCheckCopyWith<ProbeCheck> get copyWith => _$ProbeCheckCopyWithImpl<ProbeCheck>(this as ProbeCheck, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProbeCheck;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProbeCheck&&(identical(other.capability, _this.capability) || other.capability == _this.capability)&&(identical(other.passed, _this.passed) || other.passed == _this.passed)&&(identical(other.detail, _this.detail) || other.detail == _this.detail));
}


@override
int get hashCode {
  final _this = this as ProbeCheck;
  return Object.hash(runtimeType,_this.capability,_this.passed,_this.detail);
}

@override
String toString() {
  final _this = this as ProbeCheck;
  return 'ProbeCheck(capability: ${_this.capability}, passed: ${_this.passed}, detail: ${_this.detail})';
}


}

/// @nodoc
abstract mixin class $ProbeCheckCopyWith<$Res>  {
  factory $ProbeCheckCopyWith(ProbeCheck value, $Res Function(ProbeCheck) _then) = _$ProbeCheckCopyWithImpl;
@useResult
$Res call({
 String capability, bool passed, String detail
});




}
/// @nodoc
class _$ProbeCheckCopyWithImpl<$Res>
    implements $ProbeCheckCopyWith<$Res> {
  _$ProbeCheckCopyWithImpl(this._self, this._then);

  final ProbeCheck _self;
  final $Res Function(ProbeCheck) _then;

/// Create a copy of ProbeCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capability = null,Object? passed = null,Object? detail = null,}) {
  return _then(ProbeCheck(
capability: null == capability ? _self.capability : capability // ignore: cast_nullable_to_non_nullable
as String,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProbeCheck].
extension ProbeCheckPatterns on ProbeCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProbeCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProbeCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProbeCheck value)  $default,){
final _that = this;
switch (_that) {
case _ProbeCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProbeCheck value)?  $default,){
final _that = this;
switch (_that) {
case _ProbeCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capability,  bool passed,  String detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProbeCheck() when $default != null:
return $default(_that.capability,_that.passed,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capability,  bool passed,  String detail)  $default,) {final _that = this;
switch (_that) {
case _ProbeCheck():
return $default(_that.capability,_that.passed,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capability,  bool passed,  String detail)?  $default,) {final _that = this;
switch (_that) {
case _ProbeCheck() when $default != null:
return $default(_that.capability,_that.passed,_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class _ProbeCheck implements ProbeCheck {
  const _ProbeCheck({required this.capability, required this.passed, required this.detail});
  

@override final  String capability;
@override final  bool passed;
@override final  String detail;

/// Create a copy of ProbeCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProbeCheckCopyWith<_ProbeCheck> get copyWith => __$ProbeCheckCopyWithImpl<_ProbeCheck>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProbeCheck&&(identical(other.capability, capability) || other.capability == capability)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,capability,passed,detail);
}

@override
String toString() {
    return 'ProbeCheck(capability: $capability, passed: $passed, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$ProbeCheckCopyWith<$Res> implements $ProbeCheckCopyWith<$Res> {
  factory _$ProbeCheckCopyWith(_ProbeCheck value, $Res Function(_ProbeCheck) _then) = __$ProbeCheckCopyWithImpl;
@override @useResult
$Res call({
 String capability, bool passed, String detail
});




}
/// @nodoc
class __$ProbeCheckCopyWithImpl<$Res>
    implements _$ProbeCheckCopyWith<$Res> {
  __$ProbeCheckCopyWithImpl(this._self, this._then);

  final _ProbeCheck _self;
  final $Res Function(_ProbeCheck) _then;

/// Create a copy of ProbeCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capability = null,Object? passed = null,Object? detail = null,}) {
  return _then(_ProbeCheck(
capability: null == capability ? _self.capability : capability // ignore: cast_nullable_to_non_nullable
as String,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ProbeState {

 bool get busy; String get message; List<ProbeCheck> get checks; String? get qrUrl; bool get polling; bool get authenticated; bool get playable;
/// Create a copy of ProbeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProbeStateCopyWith<ProbeState> get copyWith => _$ProbeStateCopyWithImpl<ProbeState>(this as ProbeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProbeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProbeState&&(identical(other.busy, _this.busy) || other.busy == _this.busy)&&(identical(other.message, _this.message) || other.message == _this.message)&&const DeepCollectionEquality().equals(other.checks, _this.checks)&&(identical(other.qrUrl, _this.qrUrl) || other.qrUrl == _this.qrUrl)&&(identical(other.polling, _this.polling) || other.polling == _this.polling)&&(identical(other.authenticated, _this.authenticated) || other.authenticated == _this.authenticated)&&(identical(other.playable, _this.playable) || other.playable == _this.playable));
}


@override
int get hashCode {
  final _this = this as ProbeState;
  return Object.hash(runtimeType,_this.busy,_this.message,const DeepCollectionEquality().hash(_this.checks),_this.qrUrl,_this.polling,_this.authenticated,_this.playable);
}



}

/// @nodoc
abstract mixin class $ProbeStateCopyWith<$Res>  {
  factory $ProbeStateCopyWith(ProbeState value, $Res Function(ProbeState) _then) = _$ProbeStateCopyWithImpl;
@useResult
$Res call({
 bool busy, String message, List<ProbeCheck> checks, String? qrUrl, bool polling, bool authenticated, bool playable
});




}
/// @nodoc
class _$ProbeStateCopyWithImpl<$Res>
    implements $ProbeStateCopyWith<$Res> {
  _$ProbeStateCopyWithImpl(this._self, this._then);

  final ProbeState _self;
  final $Res Function(ProbeState) _then;

/// Create a copy of ProbeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? busy = null,Object? message = null,Object? checks = null,Object? qrUrl = freezed,Object? polling = null,Object? authenticated = null,Object? playable = null,}) {
  return _then(ProbeState(
busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as List<ProbeCheck>,qrUrl: freezed == qrUrl ? _self.qrUrl : qrUrl // ignore: cast_nullable_to_non_nullable
as String?,polling: null == polling ? _self.polling : polling // ignore: cast_nullable_to_non_nullable
as bool,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,playable: null == playable ? _self.playable : playable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProbeState].
extension ProbeStatePatterns on ProbeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProbeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProbeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProbeState value)  $default,){
final _that = this;
switch (_that) {
case _ProbeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProbeState value)?  $default,){
final _that = this;
switch (_that) {
case _ProbeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool busy,  String message,  List<ProbeCheck> checks,  String? qrUrl,  bool polling,  bool authenticated,  bool playable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProbeState() when $default != null:
return $default(_that.busy,_that.message,_that.checks,_that.qrUrl,_that.polling,_that.authenticated,_that.playable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool busy,  String message,  List<ProbeCheck> checks,  String? qrUrl,  bool polling,  bool authenticated,  bool playable)  $default,) {final _that = this;
switch (_that) {
case _ProbeState():
return $default(_that.busy,_that.message,_that.checks,_that.qrUrl,_that.polling,_that.authenticated,_that.playable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool busy,  String message,  List<ProbeCheck> checks,  String? qrUrl,  bool polling,  bool authenticated,  bool playable)?  $default,) {final _that = this;
switch (_that) {
case _ProbeState() when $default != null:
return $default(_that.busy,_that.message,_that.checks,_that.qrUrl,_that.polling,_that.authenticated,_that.playable);case _:
  return null;

}
}

}

/// @nodoc


class _ProbeState implements ProbeState {
  const _ProbeState({this.busy = false, this.message = '等待验证',  List<ProbeCheck> checks = const <ProbeCheck>[], this.qrUrl, this.polling = false, this.authenticated = false, this.playable = false}): _checks = checks;
  

@override@JsonKey() final  bool busy;
@override@JsonKey() final  String message;
 final  List<ProbeCheck> _checks;
@override@JsonKey() List<ProbeCheck> get checks {
  if (_checks is EqualUnmodifiableListView) return _checks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checks);
}

@override final  String? qrUrl;
@override@JsonKey() final  bool polling;
@override@JsonKey() final  bool authenticated;
@override@JsonKey() final  bool playable;

/// Create a copy of ProbeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProbeStateCopyWith<_ProbeState> get copyWith => __$ProbeStateCopyWithImpl<_ProbeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProbeState&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.checks, _checks)&&(identical(other.qrUrl, qrUrl) || other.qrUrl == qrUrl)&&(identical(other.polling, polling) || other.polling == polling)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.playable, playable) || other.playable == playable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,busy,message,const DeepCollectionEquality().hash(_checks),qrUrl,polling,authenticated,playable);
}



}

/// @nodoc
abstract mixin class _$ProbeStateCopyWith<$Res> implements $ProbeStateCopyWith<$Res> {
  factory _$ProbeStateCopyWith(_ProbeState value, $Res Function(_ProbeState) _then) = __$ProbeStateCopyWithImpl;
@override @useResult
$Res call({
 bool busy, String message, List<ProbeCheck> checks, String? qrUrl, bool polling, bool authenticated, bool playable
});




}
/// @nodoc
class __$ProbeStateCopyWithImpl<$Res>
    implements _$ProbeStateCopyWith<$Res> {
  __$ProbeStateCopyWithImpl(this._self, this._then);

  final _ProbeState _self;
  final $Res Function(_ProbeState) _then;

/// Create a copy of ProbeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? busy = null,Object? message = null,Object? checks = null,Object? qrUrl = freezed,Object? polling = null,Object? authenticated = null,Object? playable = null,}) {
  return _then(_ProbeState(
busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self._checks : checks // ignore: cast_nullable_to_non_nullable
as List<ProbeCheck>,qrUrl: freezed == qrUrl ? _self.qrUrl : qrUrl // ignore: cast_nullable_to_non_nullable
as String?,polling: null == polling ? _self.polling : polling // ignore: cast_nullable_to_non_nullable
as bool,authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,playable: null == playable ? _self.playable : playable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
