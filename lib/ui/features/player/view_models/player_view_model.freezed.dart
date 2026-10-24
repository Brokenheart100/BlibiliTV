// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerState {

 PlayerPhase get phase; EngineSnapshot get snapshot; String get title; String get partTitle; int get quality; int get surfaceGeneration; Duration get resumedFrom; AppFailure? get failure; String? get notice;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.partTitle, _this.partTitle) || other.partTitle == _this.partTitle)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.surfaceGeneration, _this.surfaceGeneration) || other.surfaceGeneration == _this.surfaceGeneration)&&(identical(other.resumedFrom, _this.resumedFrom) || other.resumedFrom == _this.resumedFrom)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as PlayerState;
  return Object.hash(runtimeType,_this.phase,_this.snapshot,_this.title,_this.partTitle,_this.quality,_this.surfaceGeneration,_this.resumedFrom,_this.failure,_this.notice);
}

@override
String toString() {
  final _this = this as PlayerState;
  return 'PlayerState(phase: ${_this.phase}, snapshot: ${_this.snapshot}, title: ${_this.title}, partTitle: ${_this.partTitle}, quality: ${_this.quality}, surfaceGeneration: ${_this.surfaceGeneration}, resumedFrom: ${_this.resumedFrom}, failure: ${_this.failure}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 PlayerPhase phase, EngineSnapshot snapshot, String title, String partTitle, int quality, int surfaceGeneration, Duration resumedFrom, AppFailure? failure, String? notice
});


$EngineSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? snapshot = null,Object? title = null,Object? partTitle = null,Object? quality = null,Object? surfaceGeneration = null,Object? resumedFrom = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(PlayerState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PlayerPhase,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EngineSnapshot,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,partTitle: null == partTitle ? _self.partTitle : partTitle // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,surfaceGeneration: null == surfaceGeneration ? _self.surfaceGeneration : surfaceGeneration // ignore: cast_nullable_to_non_nullable
as int,resumedFrom: null == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as Duration,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngineSnapshotCopyWith<$Res> get snapshot {
  
  return $EngineSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerPhase phase,  EngineSnapshot snapshot,  String title,  String partTitle,  int quality,  int surfaceGeneration,  Duration resumedFrom,  AppFailure? failure,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.phase,_that.snapshot,_that.title,_that.partTitle,_that.quality,_that.surfaceGeneration,_that.resumedFrom,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerPhase phase,  EngineSnapshot snapshot,  String title,  String partTitle,  int quality,  int surfaceGeneration,  Duration resumedFrom,  AppFailure? failure,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.phase,_that.snapshot,_that.title,_that.partTitle,_that.quality,_that.surfaceGeneration,_that.resumedFrom,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerPhase phase,  EngineSnapshot snapshot,  String title,  String partTitle,  int quality,  int surfaceGeneration,  Duration resumedFrom,  AppFailure? failure,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.phase,_that.snapshot,_that.title,_that.partTitle,_that.quality,_that.surfaceGeneration,_that.resumedFrom,_that.failure,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerState implements PlayerState {
  const _PlayerState({this.phase = PlayerPhase.idle, this.snapshot = const EngineSnapshot(), this.title = '', this.partTitle = '', this.quality = 0, this.surfaceGeneration = 0, this.resumedFrom = Duration.zero, this.failure, this.notice});
  

@override@JsonKey() final  PlayerPhase phase;
@override@JsonKey() final  EngineSnapshot snapshot;
@override@JsonKey() final  String title;
@override@JsonKey() final  String partTitle;
@override@JsonKey() final  int quality;
@override@JsonKey() final  int surfaceGeneration;
@override@JsonKey() final  Duration resumedFrom;
@override final  AppFailure? failure;
@override final  String? notice;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.title, title) || other.title == title)&&(identical(other.partTitle, partTitle) || other.partTitle == partTitle)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.surfaceGeneration, surfaceGeneration) || other.surfaceGeneration == surfaceGeneration)&&(identical(other.resumedFrom, resumedFrom) || other.resumedFrom == resumedFrom)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,snapshot,title,partTitle,quality,surfaceGeneration,resumedFrom,failure,notice);
}

@override
String toString() {
    return 'PlayerState(phase: $phase, snapshot: $snapshot, title: $title, partTitle: $partTitle, quality: $quality, surfaceGeneration: $surfaceGeneration, resumedFrom: $resumedFrom, failure: $failure, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 PlayerPhase phase, EngineSnapshot snapshot, String title, String partTitle, int quality, int surfaceGeneration, Duration resumedFrom, AppFailure? failure, String? notice
});


@override $EngineSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? snapshot = null,Object? title = null,Object? partTitle = null,Object? quality = null,Object? surfaceGeneration = null,Object? resumedFrom = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(_PlayerState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PlayerPhase,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EngineSnapshot,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,partTitle: null == partTitle ? _self.partTitle : partTitle // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,surfaceGeneration: null == surfaceGeneration ? _self.surfaceGeneration : surfaceGeneration // ignore: cast_nullable_to_non_nullable
as int,resumedFrom: null == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as Duration,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngineSnapshotCopyWith<$Res> get snapshot {
  
  return $EngineSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}

// dart format on
