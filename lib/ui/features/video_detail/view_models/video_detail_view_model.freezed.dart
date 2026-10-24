// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_detail_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoDetailState {

 VideoDetail get detail; WatchProgress? get resume; String? get notice;
/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoDetailStateCopyWith<VideoDetailState> get copyWith => _$VideoDetailStateCopyWithImpl<VideoDetailState>(this as VideoDetailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoDetailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoDetailState&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.resume, _this.resume) || other.resume == _this.resume)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as VideoDetailState;
  return Object.hash(runtimeType,_this.detail,_this.resume,_this.notice);
}

@override
String toString() {
  final _this = this as VideoDetailState;
  return 'VideoDetailState(detail: ${_this.detail}, resume: ${_this.resume}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $VideoDetailStateCopyWith<$Res>  {
  factory $VideoDetailStateCopyWith(VideoDetailState value, $Res Function(VideoDetailState) _then) = _$VideoDetailStateCopyWithImpl;
@useResult
$Res call({
 VideoDetail detail, WatchProgress? resume, String? notice
});


$VideoDetailCopyWith<$Res> get detail;

}
/// @nodoc
class _$VideoDetailStateCopyWithImpl<$Res>
    implements $VideoDetailStateCopyWith<$Res> {
  _$VideoDetailStateCopyWithImpl(this._self, this._then);

  final VideoDetailState _self;
  final $Res Function(VideoDetailState) _then;

/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? detail = null,Object? resume = freezed,Object? notice = freezed,}) {
  return _then(VideoDetailState(
detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as VideoDetail,resume: freezed == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as WatchProgress?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoDetailCopyWith<$Res> get detail {
  
  return $VideoDetailCopyWith<$Res>(_self.detail, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoDetailState].
extension VideoDetailStatePatterns on VideoDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoDetailState value)  $default,){
final _that = this;
switch (_that) {
case _VideoDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _VideoDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VideoDetail detail,  WatchProgress? resume,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoDetailState() when $default != null:
return $default(_that.detail,_that.resume,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VideoDetail detail,  WatchProgress? resume,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _VideoDetailState():
return $default(_that.detail,_that.resume,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VideoDetail detail,  WatchProgress? resume,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _VideoDetailState() when $default != null:
return $default(_that.detail,_that.resume,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _VideoDetailState implements VideoDetailState {
  const _VideoDetailState({required this.detail, this.resume, this.notice});
  

@override final  VideoDetail detail;
@override final  WatchProgress? resume;
@override final  String? notice;

/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoDetailStateCopyWith<_VideoDetailState> get copyWith => __$VideoDetailStateCopyWithImpl<_VideoDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoDetailState&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.resume, resume) || other.resume == resume)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,detail,resume,notice);
}

@override
String toString() {
    return 'VideoDetailState(detail: $detail, resume: $resume, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$VideoDetailStateCopyWith<$Res> implements $VideoDetailStateCopyWith<$Res> {
  factory _$VideoDetailStateCopyWith(_VideoDetailState value, $Res Function(_VideoDetailState) _then) = __$VideoDetailStateCopyWithImpl;
@override @useResult
$Res call({
 VideoDetail detail, WatchProgress? resume, String? notice
});


@override $VideoDetailCopyWith<$Res> get detail;

}
/// @nodoc
class __$VideoDetailStateCopyWithImpl<$Res>
    implements _$VideoDetailStateCopyWith<$Res> {
  __$VideoDetailStateCopyWithImpl(this._self, this._then);

  final _VideoDetailState _self;
  final $Res Function(_VideoDetailState) _then;

/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? detail = null,Object? resume = freezed,Object? notice = freezed,}) {
  return _then(_VideoDetailState(
detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as VideoDetail,resume: freezed == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as WatchProgress?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VideoDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoDetailCopyWith<$Res> get detail {
  
  return $VideoDetailCopyWith<$Res>(_self.detail, (value) {
    return _then(_self.copyWith(detail: value));
  });
}
}

// dart format on
