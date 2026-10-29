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

 PlayerPhase get phase; PlaybackCapabilities get capabilities; PlaybackTarget? get target; String? get overlayVideoId; String? get overlayPartId; EngineSnapshot get snapshot; String get title; String get partTitle; String get partId; List<VideoPart> get parts; List<PlaybackOption> get qualities; List<PlaybackOption> get audioTracks; int get quality; int get audioId; double get rate; double get volume; bool get autoNext; int get recoveryAttempts; int get surfaceGeneration; Duration get resumedFrom; Duration? get seekTarget; AppFailure? get failure; String? get notice;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.capabilities, _this.capabilities) || other.capabilities == _this.capabilities)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.overlayVideoId, _this.overlayVideoId) || other.overlayVideoId == _this.overlayVideoId)&&(identical(other.overlayPartId, _this.overlayPartId) || other.overlayPartId == _this.overlayPartId)&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.partTitle, _this.partTitle) || other.partTitle == _this.partTitle)&&(identical(other.partId, _this.partId) || other.partId == _this.partId)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.qualities, _this.qualities)&&const DeepCollectionEquality().equals(other.audioTracks, _this.audioTracks)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.audioId, _this.audioId) || other.audioId == _this.audioId)&&(identical(other.rate, _this.rate) || other.rate == _this.rate)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.autoNext, _this.autoNext) || other.autoNext == _this.autoNext)&&(identical(other.recoveryAttempts, _this.recoveryAttempts) || other.recoveryAttempts == _this.recoveryAttempts)&&(identical(other.surfaceGeneration, _this.surfaceGeneration) || other.surfaceGeneration == _this.surfaceGeneration)&&(identical(other.resumedFrom, _this.resumedFrom) || other.resumedFrom == _this.resumedFrom)&&(identical(other.seekTarget, _this.seekTarget) || other.seekTarget == _this.seekTarget)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as PlayerState;
  return Object.hashAll([runtimeType,_this.phase,_this.capabilities,_this.target,_this.overlayVideoId,_this.overlayPartId,_this.snapshot,_this.title,_this.partTitle,_this.partId,const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.qualities),const DeepCollectionEquality().hash(_this.audioTracks),_this.quality,_this.audioId,_this.rate,_this.volume,_this.autoNext,_this.recoveryAttempts,_this.surfaceGeneration,_this.resumedFrom,_this.seekTarget,_this.failure,_this.notice]);
}

@override
String toString() {
  final _this = this as PlayerState;
  return 'PlayerState(phase: ${_this.phase}, capabilities: ${_this.capabilities}, target: ${_this.target}, overlayVideoId: ${_this.overlayVideoId}, overlayPartId: ${_this.overlayPartId}, snapshot: ${_this.snapshot}, title: ${_this.title}, partTitle: ${_this.partTitle}, partId: ${_this.partId}, parts: ${_this.parts}, qualities: ${_this.qualities}, audioTracks: ${_this.audioTracks}, quality: ${_this.quality}, audioId: ${_this.audioId}, rate: ${_this.rate}, volume: ${_this.volume}, autoNext: ${_this.autoNext}, recoveryAttempts: ${_this.recoveryAttempts}, surfaceGeneration: ${_this.surfaceGeneration}, resumedFrom: ${_this.resumedFrom}, seekTarget: ${_this.seekTarget}, failure: ${_this.failure}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 PlayerPhase phase, PlaybackCapabilities capabilities, PlaybackTarget? target, String? overlayVideoId, String? overlayPartId, EngineSnapshot snapshot, String title, String partTitle, String partId, List<VideoPart> parts, List<PlaybackOption> qualities, List<PlaybackOption> audioTracks, int quality, int audioId, double rate, double volume, bool autoNext, int recoveryAttempts, int surfaceGeneration, Duration resumedFrom, Duration? seekTarget, AppFailure? failure, String? notice
});


$PlaybackCapabilitiesCopyWith<$Res> get capabilities;$PlaybackTargetCopyWith<$Res>? get target;$EngineSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? capabilities = null,Object? target = freezed,Object? overlayVideoId = freezed,Object? overlayPartId = freezed,Object? snapshot = null,Object? title = null,Object? partTitle = null,Object? partId = null,Object? parts = null,Object? qualities = null,Object? audioTracks = null,Object? quality = null,Object? audioId = null,Object? rate = null,Object? volume = null,Object? autoNext = null,Object? recoveryAttempts = null,Object? surfaceGeneration = null,Object? resumedFrom = null,Object? seekTarget = freezed,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(PlayerState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PlayerPhase,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as PlaybackCapabilities,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PlaybackTarget?,overlayVideoId: freezed == overlayVideoId ? _self.overlayVideoId : overlayVideoId // ignore: cast_nullable_to_non_nullable
as String?,overlayPartId: freezed == overlayPartId ? _self.overlayPartId : overlayPartId // ignore: cast_nullable_to_non_nullable
as String?,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EngineSnapshot,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,partTitle: null == partTitle ? _self.partTitle : partTitle // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<VideoPart>,qualities: null == qualities ? _self.qualities : qualities // ignore: cast_nullable_to_non_nullable
as List<PlaybackOption>,audioTracks: null == audioTracks ? _self.audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<PlaybackOption>,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,audioId: null == audioId ? _self.audioId : audioId // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,autoNext: null == autoNext ? _self.autoNext : autoNext // ignore: cast_nullable_to_non_nullable
as bool,recoveryAttempts: null == recoveryAttempts ? _self.recoveryAttempts : recoveryAttempts // ignore: cast_nullable_to_non_nullable
as int,surfaceGeneration: null == surfaceGeneration ? _self.surfaceGeneration : surfaceGeneration // ignore: cast_nullable_to_non_nullable
as int,resumedFrom: null == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as Duration,seekTarget: freezed == seekTarget ? _self.seekTarget : seekTarget // ignore: cast_nullable_to_non_nullable
as Duration?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackCapabilitiesCopyWith<$Res> get capabilities {
  
  return $PlaybackCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackTargetCopyWith<$Res>? get target {
    if (_self.target == null) {
    return null;
  }

  return $PlaybackTargetCopyWith<$Res>(_self.target!, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of PlayerState
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerPhase phase,  PlaybackCapabilities capabilities,  PlaybackTarget? target,  String? overlayVideoId,  String? overlayPartId,  EngineSnapshot snapshot,  String title,  String partTitle,  String partId,  List<VideoPart> parts,  List<PlaybackOption> qualities,  List<PlaybackOption> audioTracks,  int quality,  int audioId,  double rate,  double volume,  bool autoNext,  int recoveryAttempts,  int surfaceGeneration,  Duration resumedFrom,  Duration? seekTarget,  AppFailure? failure,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.phase,_that.capabilities,_that.target,_that.overlayVideoId,_that.overlayPartId,_that.snapshot,_that.title,_that.partTitle,_that.partId,_that.parts,_that.qualities,_that.audioTracks,_that.quality,_that.audioId,_that.rate,_that.volume,_that.autoNext,_that.recoveryAttempts,_that.surfaceGeneration,_that.resumedFrom,_that.seekTarget,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerPhase phase,  PlaybackCapabilities capabilities,  PlaybackTarget? target,  String? overlayVideoId,  String? overlayPartId,  EngineSnapshot snapshot,  String title,  String partTitle,  String partId,  List<VideoPart> parts,  List<PlaybackOption> qualities,  List<PlaybackOption> audioTracks,  int quality,  int audioId,  double rate,  double volume,  bool autoNext,  int recoveryAttempts,  int surfaceGeneration,  Duration resumedFrom,  Duration? seekTarget,  AppFailure? failure,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.phase,_that.capabilities,_that.target,_that.overlayVideoId,_that.overlayPartId,_that.snapshot,_that.title,_that.partTitle,_that.partId,_that.parts,_that.qualities,_that.audioTracks,_that.quality,_that.audioId,_that.rate,_that.volume,_that.autoNext,_that.recoveryAttempts,_that.surfaceGeneration,_that.resumedFrom,_that.seekTarget,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerPhase phase,  PlaybackCapabilities capabilities,  PlaybackTarget? target,  String? overlayVideoId,  String? overlayPartId,  EngineSnapshot snapshot,  String title,  String partTitle,  String partId,  List<VideoPart> parts,  List<PlaybackOption> qualities,  List<PlaybackOption> audioTracks,  int quality,  int audioId,  double rate,  double volume,  bool autoNext,  int recoveryAttempts,  int surfaceGeneration,  Duration resumedFrom,  Duration? seekTarget,  AppFailure? failure,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.phase,_that.capabilities,_that.target,_that.overlayVideoId,_that.overlayPartId,_that.snapshot,_that.title,_that.partTitle,_that.partId,_that.parts,_that.qualities,_that.audioTracks,_that.quality,_that.audioId,_that.rate,_that.volume,_that.autoNext,_that.recoveryAttempts,_that.surfaceGeneration,_that.resumedFrom,_that.seekTarget,_that.failure,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerState implements PlayerState {
  const _PlayerState({this.phase = PlayerPhase.idle, this.capabilities = const PlaybackCapabilities(), this.target, this.overlayVideoId, this.overlayPartId, this.snapshot = const EngineSnapshot(), this.title = '', this.partTitle = '', this.partId = '',  List<VideoPart> parts = const <VideoPart>[],  List<PlaybackOption> qualities = const <PlaybackOption>[],  List<PlaybackOption> audioTracks = const <PlaybackOption>[], this.quality = 0, this.audioId = 0, this.rate = 1.0, this.volume = 100.0, this.autoNext = false, this.recoveryAttempts = 0, this.surfaceGeneration = 0, this.resumedFrom = Duration.zero, this.seekTarget, this.failure, this.notice}): _parts = parts,_qualities = qualities,_audioTracks = audioTracks;
  

@override@JsonKey() final  PlayerPhase phase;
@override@JsonKey() final  PlaybackCapabilities capabilities;
@override final  PlaybackTarget? target;
@override final  String? overlayVideoId;
@override final  String? overlayPartId;
@override@JsonKey() final  EngineSnapshot snapshot;
@override@JsonKey() final  String title;
@override@JsonKey() final  String partTitle;
@override@JsonKey() final  String partId;
 final  List<VideoPart> _parts;
@override@JsonKey() List<VideoPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

 final  List<PlaybackOption> _qualities;
@override@JsonKey() List<PlaybackOption> get qualities {
  if (_qualities is EqualUnmodifiableListView) return _qualities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_qualities);
}

 final  List<PlaybackOption> _audioTracks;
@override@JsonKey() List<PlaybackOption> get audioTracks {
  if (_audioTracks is EqualUnmodifiableListView) return _audioTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audioTracks);
}

@override@JsonKey() final  int quality;
@override@JsonKey() final  int audioId;
@override@JsonKey() final  double rate;
@override@JsonKey() final  double volume;
@override@JsonKey() final  bool autoNext;
@override@JsonKey() final  int recoveryAttempts;
@override@JsonKey() final  int surfaceGeneration;
@override@JsonKey() final  Duration resumedFrom;
@override final  Duration? seekTarget;
@override final  AppFailure? failure;
@override final  String? notice;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.capabilities, capabilities) || other.capabilities == capabilities)&&(identical(other.target, target) || other.target == target)&&(identical(other.overlayVideoId, overlayVideoId) || other.overlayVideoId == overlayVideoId)&&(identical(other.overlayPartId, overlayPartId) || other.overlayPartId == overlayPartId)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.title, title) || other.title == title)&&(identical(other.partTitle, partTitle) || other.partTitle == partTitle)&&(identical(other.partId, partId) || other.partId == partId)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.qualities, _qualities)&&const DeepCollectionEquality().equals(other.audioTracks, _audioTracks)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.audioId, audioId) || other.audioId == audioId)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.autoNext, autoNext) || other.autoNext == autoNext)&&(identical(other.recoveryAttempts, recoveryAttempts) || other.recoveryAttempts == recoveryAttempts)&&(identical(other.surfaceGeneration, surfaceGeneration) || other.surfaceGeneration == surfaceGeneration)&&(identical(other.resumedFrom, resumedFrom) || other.resumedFrom == resumedFrom)&&(identical(other.seekTarget, seekTarget) || other.seekTarget == seekTarget)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,phase,capabilities,target,overlayVideoId,overlayPartId,snapshot,title,partTitle,partId,const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_qualities),const DeepCollectionEquality().hash(_audioTracks),quality,audioId,rate,volume,autoNext,recoveryAttempts,surfaceGeneration,resumedFrom,seekTarget,failure,notice]);
}

@override
String toString() {
    return 'PlayerState(phase: $phase, capabilities: $capabilities, target: $target, overlayVideoId: $overlayVideoId, overlayPartId: $overlayPartId, snapshot: $snapshot, title: $title, partTitle: $partTitle, partId: $partId, parts: $parts, qualities: $qualities, audioTracks: $audioTracks, quality: $quality, audioId: $audioId, rate: $rate, volume: $volume, autoNext: $autoNext, recoveryAttempts: $recoveryAttempts, surfaceGeneration: $surfaceGeneration, resumedFrom: $resumedFrom, seekTarget: $seekTarget, failure: $failure, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 PlayerPhase phase, PlaybackCapabilities capabilities, PlaybackTarget? target, String? overlayVideoId, String? overlayPartId, EngineSnapshot snapshot, String title, String partTitle, String partId, List<VideoPart> parts, List<PlaybackOption> qualities, List<PlaybackOption> audioTracks, int quality, int audioId, double rate, double volume, bool autoNext, int recoveryAttempts, int surfaceGeneration, Duration resumedFrom, Duration? seekTarget, AppFailure? failure, String? notice
});


@override $PlaybackCapabilitiesCopyWith<$Res> get capabilities;@override $PlaybackTargetCopyWith<$Res>? get target;@override $EngineSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? capabilities = null,Object? target = freezed,Object? overlayVideoId = freezed,Object? overlayPartId = freezed,Object? snapshot = null,Object? title = null,Object? partTitle = null,Object? partId = null,Object? parts = null,Object? qualities = null,Object? audioTracks = null,Object? quality = null,Object? audioId = null,Object? rate = null,Object? volume = null,Object? autoNext = null,Object? recoveryAttempts = null,Object? surfaceGeneration = null,Object? resumedFrom = null,Object? seekTarget = freezed,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(_PlayerState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PlayerPhase,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as PlaybackCapabilities,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PlaybackTarget?,overlayVideoId: freezed == overlayVideoId ? _self.overlayVideoId : overlayVideoId // ignore: cast_nullable_to_non_nullable
as String?,overlayPartId: freezed == overlayPartId ? _self.overlayPartId : overlayPartId // ignore: cast_nullable_to_non_nullable
as String?,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as EngineSnapshot,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,partTitle: null == partTitle ? _self.partTitle : partTitle // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<VideoPart>,qualities: null == qualities ? _self._qualities : qualities // ignore: cast_nullable_to_non_nullable
as List<PlaybackOption>,audioTracks: null == audioTracks ? _self._audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as List<PlaybackOption>,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,audioId: null == audioId ? _self.audioId : audioId // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,autoNext: null == autoNext ? _self.autoNext : autoNext // ignore: cast_nullable_to_non_nullable
as bool,recoveryAttempts: null == recoveryAttempts ? _self.recoveryAttempts : recoveryAttempts // ignore: cast_nullable_to_non_nullable
as int,surfaceGeneration: null == surfaceGeneration ? _self.surfaceGeneration : surfaceGeneration // ignore: cast_nullable_to_non_nullable
as int,resumedFrom: null == resumedFrom ? _self.resumedFrom : resumedFrom // ignore: cast_nullable_to_non_nullable
as Duration,seekTarget: freezed == seekTarget ? _self.seekTarget : seekTarget // ignore: cast_nullable_to_non_nullable
as Duration?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackCapabilitiesCopyWith<$Res> get capabilities {
  
  return $PlaybackCapabilitiesCopyWith<$Res>(_self.capabilities, (value) {
    return _then(_self.copyWith(capabilities: value));
  });
}/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackTargetCopyWith<$Res>? get target {
    if (_self.target == null) {
    return null;
  }

  return $PlaybackTargetCopyWith<$Res>(_self.target!, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of PlayerState
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
