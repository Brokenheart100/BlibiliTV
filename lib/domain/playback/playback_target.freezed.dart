// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackTarget {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackTarget);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PlaybackTarget()';
}


}

/// @nodoc
class $PlaybackTargetCopyWith<$Res>  {
$PlaybackTargetCopyWith(PlaybackTarget _, $Res Function(PlaybackTarget) __);
}


/// Adds pattern-matching-related methods to [PlaybackTarget].
extension PlaybackTargetPatterns on PlaybackTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UgcTarget value)?  ugc,TResult Function( PgcTarget value)?  pgc,TResult Function( LiveTarget value)?  live,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UgcTarget() when ugc != null:
return ugc(_that);case PgcTarget() when pgc != null:
return pgc(_that);case LiveTarget() when live != null:
return live(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UgcTarget value)  ugc,required TResult Function( PgcTarget value)  pgc,required TResult Function( LiveTarget value)  live,}){
final _that = this;
switch (_that) {
case UgcTarget():
return ugc(_that);case PgcTarget():
return pgc(_that);case LiveTarget():
return live(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UgcTarget value)?  ugc,TResult? Function( PgcTarget value)?  pgc,TResult? Function( LiveTarget value)?  live,}){
final _that = this;
switch (_that) {
case UgcTarget() when ugc != null:
return ugc(_that);case PgcTarget() when pgc != null:
return pgc(_that);case LiveTarget() when live != null:
return live(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String bvid,  String? cid)?  ugc,TResult Function( String seasonId,  String episodeId)?  pgc,TResult Function( String roomId)?  live,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UgcTarget() when ugc != null:
return ugc(_that.bvid,_that.cid);case PgcTarget() when pgc != null:
return pgc(_that.seasonId,_that.episodeId);case LiveTarget() when live != null:
return live(_that.roomId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String bvid,  String? cid)  ugc,required TResult Function( String seasonId,  String episodeId)  pgc,required TResult Function( String roomId)  live,}) {final _that = this;
switch (_that) {
case UgcTarget():
return ugc(_that.bvid,_that.cid);case PgcTarget():
return pgc(_that.seasonId,_that.episodeId);case LiveTarget():
return live(_that.roomId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String bvid,  String? cid)?  ugc,TResult? Function( String seasonId,  String episodeId)?  pgc,TResult? Function( String roomId)?  live,}) {final _that = this;
switch (_that) {
case UgcTarget() when ugc != null:
return ugc(_that.bvid,_that.cid);case PgcTarget() when pgc != null:
return pgc(_that.seasonId,_that.episodeId);case LiveTarget() when live != null:
return live(_that.roomId);case _:
  return null;

}
}

}

/// @nodoc


class UgcTarget extends PlaybackTarget {
  const UgcTarget({required this.bvid, this.cid}): super._();
  

 final  String bvid;
 final  String? cid;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UgcTargetCopyWith<UgcTarget> get copyWith => _$UgcTargetCopyWithImpl<UgcTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UgcTarget&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bvid,cid);
}

@override
String toString() {
    return 'PlaybackTarget.ugc(bvid: $bvid, cid: $cid)';
}


}

/// @nodoc
abstract mixin class $UgcTargetCopyWith<$Res> implements $PlaybackTargetCopyWith<$Res> {
  factory $UgcTargetCopyWith(UgcTarget value, $Res Function(UgcTarget) _then) = _$UgcTargetCopyWithImpl;
@useResult
$Res call({
 String bvid, String? cid
});




}
/// @nodoc
class _$UgcTargetCopyWithImpl<$Res>
    implements $UgcTargetCopyWith<$Res> {
  _$UgcTargetCopyWithImpl(this._self, this._then);

  final UgcTarget _self;
  final $Res Function(UgcTarget) _then;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? cid = freezed,}) {
  return _then(UgcTarget(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: freezed == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PgcTarget extends PlaybackTarget {
  const PgcTarget({required this.seasonId, required this.episodeId}): super._();
  

 final  String seasonId;
 final  String episodeId;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PgcTargetCopyWith<PgcTarget> get copyWith => _$PgcTargetCopyWithImpl<PgcTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcTarget&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.episodeId, episodeId) || other.episodeId == episodeId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,episodeId);
}

@override
String toString() {
    return 'PlaybackTarget.pgc(seasonId: $seasonId, episodeId: $episodeId)';
}


}

/// @nodoc
abstract mixin class $PgcTargetCopyWith<$Res> implements $PlaybackTargetCopyWith<$Res> {
  factory $PgcTargetCopyWith(PgcTarget value, $Res Function(PgcTarget) _then) = _$PgcTargetCopyWithImpl;
@useResult
$Res call({
 String seasonId, String episodeId
});




}
/// @nodoc
class _$PgcTargetCopyWithImpl<$Res>
    implements $PgcTargetCopyWith<$Res> {
  _$PgcTargetCopyWithImpl(this._self, this._then);

  final PgcTarget _self;
  final $Res Function(PgcTarget) _then;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? episodeId = null,}) {
  return _then(PgcTarget(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,episodeId: null == episodeId ? _self.episodeId : episodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LiveTarget extends PlaybackTarget {
  const LiveTarget({required this.roomId}): super._();
  

 final  String roomId;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveTargetCopyWith<LiveTarget> get copyWith => _$LiveTargetCopyWithImpl<LiveTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveTarget&&(identical(other.roomId, roomId) || other.roomId == roomId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,roomId);
}

@override
String toString() {
    return 'PlaybackTarget.live(roomId: $roomId)';
}


}

/// @nodoc
abstract mixin class $LiveTargetCopyWith<$Res> implements $PlaybackTargetCopyWith<$Res> {
  factory $LiveTargetCopyWith(LiveTarget value, $Res Function(LiveTarget) _then) = _$LiveTargetCopyWithImpl;
@useResult
$Res call({
 String roomId
});




}
/// @nodoc
class _$LiveTargetCopyWithImpl<$Res>
    implements $LiveTargetCopyWith<$Res> {
  _$LiveTargetCopyWithImpl(this._self, this._then);

  final LiveTarget _self;
  final $Res Function(LiveTarget) _then;

/// Create a copy of PlaybackTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roomId = null,}) {
  return _then(LiveTarget(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlaybackCapabilities {

 bool get seek; bool get rate; bool get duration; bool get parts; bool get audioTracks; bool get subtitles; bool get danmaku; bool get resume; bool get remoteHistory;
/// Create a copy of PlaybackCapabilities
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackCapabilitiesCopyWith<PlaybackCapabilities> get copyWith => _$PlaybackCapabilitiesCopyWithImpl<PlaybackCapabilities>(this as PlaybackCapabilities, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaybackCapabilities;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackCapabilities&&(identical(other.seek, _this.seek) || other.seek == _this.seek)&&(identical(other.rate, _this.rate) || other.rate == _this.rate)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.parts, _this.parts) || other.parts == _this.parts)&&(identical(other.audioTracks, _this.audioTracks) || other.audioTracks == _this.audioTracks)&&(identical(other.subtitles, _this.subtitles) || other.subtitles == _this.subtitles)&&(identical(other.danmaku, _this.danmaku) || other.danmaku == _this.danmaku)&&(identical(other.resume, _this.resume) || other.resume == _this.resume)&&(identical(other.remoteHistory, _this.remoteHistory) || other.remoteHistory == _this.remoteHistory));
}


@override
int get hashCode {
  final _this = this as PlaybackCapabilities;
  return Object.hash(runtimeType,_this.seek,_this.rate,_this.duration,_this.parts,_this.audioTracks,_this.subtitles,_this.danmaku,_this.resume,_this.remoteHistory);
}

@override
String toString() {
  final _this = this as PlaybackCapabilities;
  return 'PlaybackCapabilities(seek: ${_this.seek}, rate: ${_this.rate}, duration: ${_this.duration}, parts: ${_this.parts}, audioTracks: ${_this.audioTracks}, subtitles: ${_this.subtitles}, danmaku: ${_this.danmaku}, resume: ${_this.resume}, remoteHistory: ${_this.remoteHistory})';
}


}

/// @nodoc
abstract mixin class $PlaybackCapabilitiesCopyWith<$Res>  {
  factory $PlaybackCapabilitiesCopyWith(PlaybackCapabilities value, $Res Function(PlaybackCapabilities) _then) = _$PlaybackCapabilitiesCopyWithImpl;
@useResult
$Res call({
 bool seek, bool rate, bool duration, bool parts, bool audioTracks, bool subtitles, bool danmaku, bool resume, bool remoteHistory
});




}
/// @nodoc
class _$PlaybackCapabilitiesCopyWithImpl<$Res>
    implements $PlaybackCapabilitiesCopyWith<$Res> {
  _$PlaybackCapabilitiesCopyWithImpl(this._self, this._then);

  final PlaybackCapabilities _self;
  final $Res Function(PlaybackCapabilities) _then;

/// Create a copy of PlaybackCapabilities
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seek = null,Object? rate = null,Object? duration = null,Object? parts = null,Object? audioTracks = null,Object? subtitles = null,Object? danmaku = null,Object? resume = null,Object? remoteHistory = null,}) {
  return _then(PlaybackCapabilities(
seek: null == seek ? _self.seek : seek // ignore: cast_nullable_to_non_nullable
as bool,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as bool,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as bool,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as bool,audioTracks: null == audioTracks ? _self.audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as bool,subtitles: null == subtitles ? _self.subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as bool,danmaku: null == danmaku ? _self.danmaku : danmaku // ignore: cast_nullable_to_non_nullable
as bool,resume: null == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as bool,remoteHistory: null == remoteHistory ? _self.remoteHistory : remoteHistory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackCapabilities].
extension PlaybackCapabilitiesPatterns on PlaybackCapabilities {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackCapabilities value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackCapabilities() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackCapabilities value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackCapabilities():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackCapabilities value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackCapabilities() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool seek,  bool rate,  bool duration,  bool parts,  bool audioTracks,  bool subtitles,  bool danmaku,  bool resume,  bool remoteHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackCapabilities() when $default != null:
return $default(_that.seek,_that.rate,_that.duration,_that.parts,_that.audioTracks,_that.subtitles,_that.danmaku,_that.resume,_that.remoteHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool seek,  bool rate,  bool duration,  bool parts,  bool audioTracks,  bool subtitles,  bool danmaku,  bool resume,  bool remoteHistory)  $default,) {final _that = this;
switch (_that) {
case _PlaybackCapabilities():
return $default(_that.seek,_that.rate,_that.duration,_that.parts,_that.audioTracks,_that.subtitles,_that.danmaku,_that.resume,_that.remoteHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool seek,  bool rate,  bool duration,  bool parts,  bool audioTracks,  bool subtitles,  bool danmaku,  bool resume,  bool remoteHistory)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackCapabilities() when $default != null:
return $default(_that.seek,_that.rate,_that.duration,_that.parts,_that.audioTracks,_that.subtitles,_that.danmaku,_that.resume,_that.remoteHistory);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackCapabilities implements PlaybackCapabilities {
  const _PlaybackCapabilities({this.seek = true, this.rate = true, this.duration = true, this.parts = true, this.audioTracks = true, this.subtitles = true, this.danmaku = true, this.resume = true, this.remoteHistory = true});
  

@override@JsonKey() final  bool seek;
@override@JsonKey() final  bool rate;
@override@JsonKey() final  bool duration;
@override@JsonKey() final  bool parts;
@override@JsonKey() final  bool audioTracks;
@override@JsonKey() final  bool subtitles;
@override@JsonKey() final  bool danmaku;
@override@JsonKey() final  bool resume;
@override@JsonKey() final  bool remoteHistory;

/// Create a copy of PlaybackCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackCapabilitiesCopyWith<_PlaybackCapabilities> get copyWith => __$PlaybackCapabilitiesCopyWithImpl<_PlaybackCapabilities>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackCapabilities&&(identical(other.seek, seek) || other.seek == seek)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.parts, parts) || other.parts == parts)&&(identical(other.audioTracks, audioTracks) || other.audioTracks == audioTracks)&&(identical(other.subtitles, subtitles) || other.subtitles == subtitles)&&(identical(other.danmaku, danmaku) || other.danmaku == danmaku)&&(identical(other.resume, resume) || other.resume == resume)&&(identical(other.remoteHistory, remoteHistory) || other.remoteHistory == remoteHistory));
}


@override
int get hashCode {
    return Object.hash(runtimeType,seek,rate,duration,parts,audioTracks,subtitles,danmaku,resume,remoteHistory);
}

@override
String toString() {
    return 'PlaybackCapabilities(seek: $seek, rate: $rate, duration: $duration, parts: $parts, audioTracks: $audioTracks, subtitles: $subtitles, danmaku: $danmaku, resume: $resume, remoteHistory: $remoteHistory)';
}


}

/// @nodoc
abstract mixin class _$PlaybackCapabilitiesCopyWith<$Res> implements $PlaybackCapabilitiesCopyWith<$Res> {
  factory _$PlaybackCapabilitiesCopyWith(_PlaybackCapabilities value, $Res Function(_PlaybackCapabilities) _then) = __$PlaybackCapabilitiesCopyWithImpl;
@override @useResult
$Res call({
 bool seek, bool rate, bool duration, bool parts, bool audioTracks, bool subtitles, bool danmaku, bool resume, bool remoteHistory
});




}
/// @nodoc
class __$PlaybackCapabilitiesCopyWithImpl<$Res>
    implements _$PlaybackCapabilitiesCopyWith<$Res> {
  __$PlaybackCapabilitiesCopyWithImpl(this._self, this._then);

  final _PlaybackCapabilities _self;
  final $Res Function(_PlaybackCapabilities) _then;

/// Create a copy of PlaybackCapabilities
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seek = null,Object? rate = null,Object? duration = null,Object? parts = null,Object? audioTracks = null,Object? subtitles = null,Object? danmaku = null,Object? resume = null,Object? remoteHistory = null,}) {
  return _then(_PlaybackCapabilities(
seek: null == seek ? _self.seek : seek // ignore: cast_nullable_to_non_nullable
as bool,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as bool,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as bool,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as bool,audioTracks: null == audioTracks ? _self.audioTracks : audioTracks // ignore: cast_nullable_to_non_nullable
as bool,subtitles: null == subtitles ? _self.subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as bool,danmaku: null == danmaku ? _self.danmaku : danmaku // ignore: cast_nullable_to_non_nullable
as bool,resume: null == resume ? _self.resume : resume // ignore: cast_nullable_to_non_nullable
as bool,remoteHistory: null == remoteHistory ? _self.remoteHistory : remoteHistory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
