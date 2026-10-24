// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EngineSnapshot {

 bool get playing; bool get buffering; bool get completed; Duration get position; Duration get duration; int get width; int get height; int get audioSampleRate; AppFailure? get failure;
/// Create a copy of EngineSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngineSnapshotCopyWith<EngineSnapshot> get copyWith => _$EngineSnapshotCopyWithImpl<EngineSnapshot>(this as EngineSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EngineSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngineSnapshot&&(identical(other.playing, _this.playing) || other.playing == _this.playing)&&(identical(other.buffering, _this.buffering) || other.buffering == _this.buffering)&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.audioSampleRate, _this.audioSampleRate) || other.audioSampleRate == _this.audioSampleRate)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as EngineSnapshot;
  return Object.hash(runtimeType,_this.playing,_this.buffering,_this.completed,_this.position,_this.duration,_this.width,_this.height,_this.audioSampleRate,_this.failure);
}

@override
String toString() {
  final _this = this as EngineSnapshot;
  return 'EngineSnapshot(playing: ${_this.playing}, buffering: ${_this.buffering}, completed: ${_this.completed}, position: ${_this.position}, duration: ${_this.duration}, width: ${_this.width}, height: ${_this.height}, audioSampleRate: ${_this.audioSampleRate}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $EngineSnapshotCopyWith<$Res>  {
  factory $EngineSnapshotCopyWith(EngineSnapshot value, $Res Function(EngineSnapshot) _then) = _$EngineSnapshotCopyWithImpl;
@useResult
$Res call({
 bool playing, bool buffering, bool completed, Duration position, Duration duration, int width, int height, int audioSampleRate, AppFailure? failure
});




}
/// @nodoc
class _$EngineSnapshotCopyWithImpl<$Res>
    implements $EngineSnapshotCopyWith<$Res> {
  _$EngineSnapshotCopyWithImpl(this._self, this._then);

  final EngineSnapshot _self;
  final $Res Function(EngineSnapshot) _then;

/// Create a copy of EngineSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playing = null,Object? buffering = null,Object? completed = null,Object? position = null,Object? duration = null,Object? width = null,Object? height = null,Object? audioSampleRate = null,Object? failure = freezed,}) {
  return _then(EngineSnapshot(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,buffering: null == buffering ? _self.buffering : buffering // ignore: cast_nullable_to_non_nullable
as bool,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,audioSampleRate: null == audioSampleRate ? _self.audioSampleRate : audioSampleRate // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [EngineSnapshot].
extension EngineSnapshotPatterns on EngineSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EngineSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EngineSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EngineSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _EngineSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EngineSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _EngineSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool playing,  bool buffering,  bool completed,  Duration position,  Duration duration,  int width,  int height,  int audioSampleRate,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EngineSnapshot() when $default != null:
return $default(_that.playing,_that.buffering,_that.completed,_that.position,_that.duration,_that.width,_that.height,_that.audioSampleRate,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool playing,  bool buffering,  bool completed,  Duration position,  Duration duration,  int width,  int height,  int audioSampleRate,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _EngineSnapshot():
return $default(_that.playing,_that.buffering,_that.completed,_that.position,_that.duration,_that.width,_that.height,_that.audioSampleRate,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool playing,  bool buffering,  bool completed,  Duration position,  Duration duration,  int width,  int height,  int audioSampleRate,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _EngineSnapshot() when $default != null:
return $default(_that.playing,_that.buffering,_that.completed,_that.position,_that.duration,_that.width,_that.height,_that.audioSampleRate,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _EngineSnapshot implements EngineSnapshot {
  const _EngineSnapshot({this.playing = false, this.buffering = false, this.completed = false, this.position = Duration.zero, this.duration = Duration.zero, this.width = 0, this.height = 0, this.audioSampleRate = 0, this.failure});
  

@override@JsonKey() final  bool playing;
@override@JsonKey() final  bool buffering;
@override@JsonKey() final  bool completed;
@override@JsonKey() final  Duration position;
@override@JsonKey() final  Duration duration;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
@override@JsonKey() final  int audioSampleRate;
@override final  AppFailure? failure;

/// Create a copy of EngineSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngineSnapshotCopyWith<_EngineSnapshot> get copyWith => __$EngineSnapshotCopyWithImpl<_EngineSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngineSnapshot&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.buffering, buffering) || other.buffering == buffering)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.audioSampleRate, audioSampleRate) || other.audioSampleRate == audioSampleRate)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playing,buffering,completed,position,duration,width,height,audioSampleRate,failure);
}

@override
String toString() {
    return 'EngineSnapshot(playing: $playing, buffering: $buffering, completed: $completed, position: $position, duration: $duration, width: $width, height: $height, audioSampleRate: $audioSampleRate, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$EngineSnapshotCopyWith<$Res> implements $EngineSnapshotCopyWith<$Res> {
  factory _$EngineSnapshotCopyWith(_EngineSnapshot value, $Res Function(_EngineSnapshot) _then) = __$EngineSnapshotCopyWithImpl;
@override @useResult
$Res call({
 bool playing, bool buffering, bool completed, Duration position, Duration duration, int width, int height, int audioSampleRate, AppFailure? failure
});




}
/// @nodoc
class __$EngineSnapshotCopyWithImpl<$Res>
    implements _$EngineSnapshotCopyWith<$Res> {
  __$EngineSnapshotCopyWithImpl(this._self, this._then);

  final _EngineSnapshot _self;
  final $Res Function(_EngineSnapshot) _then;

/// Create a copy of EngineSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playing = null,Object? buffering = null,Object? completed = null,Object? position = null,Object? duration = null,Object? width = null,Object? height = null,Object? audioSampleRate = null,Object? failure = freezed,}) {
  return _then(_EngineSnapshot(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,buffering: null == buffering ? _self.buffering : buffering // ignore: cast_nullable_to_non_nullable
as bool,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,audioSampleRate: null == audioSampleRate ? _self.audioSampleRate : audioSampleRate // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
