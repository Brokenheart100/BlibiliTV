// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overlay_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubtitleState {

 List<SubtitleTrack> get tracks; List<SubtitleCue> get cues; String? get selected; bool get loading; AppFailure? get failure;
/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleStateCopyWith<SubtitleState> get copyWith => _$SubtitleStateCopyWithImpl<SubtitleState>(this as SubtitleState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubtitleState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleState&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.cues, _this.cues)&&(identical(other.selected, _this.selected) || other.selected == _this.selected)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as SubtitleState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.cues),_this.selected,_this.loading,_this.failure);
}

@override
String toString() {
  final _this = this as SubtitleState;
  return 'SubtitleState(tracks: ${_this.tracks}, cues: ${_this.cues}, selected: ${_this.selected}, loading: ${_this.loading}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $SubtitleStateCopyWith<$Res>  {
  factory $SubtitleStateCopyWith(SubtitleState value, $Res Function(SubtitleState) _then) = _$SubtitleStateCopyWithImpl;
@useResult
$Res call({
 List<SubtitleTrack> tracks, List<SubtitleCue> cues, String? selected, bool loading, AppFailure? failure
});




}
/// @nodoc
class _$SubtitleStateCopyWithImpl<$Res>
    implements $SubtitleStateCopyWith<$Res> {
  _$SubtitleStateCopyWithImpl(this._self, this._then);

  final SubtitleState _self;
  final $Res Function(SubtitleState) _then;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,Object? cues = null,Object? selected = freezed,Object? loading = null,Object? failure = freezed,}) {
  return _then(SubtitleState(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,cues: null == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as List<SubtitleCue>,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleState].
extension SubtitleStatePatterns on SubtitleState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleState value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleState value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubtitleTrack> tracks,  List<SubtitleCue> cues,  String? selected,  bool loading,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
return $default(_that.tracks,_that.cues,_that.selected,_that.loading,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubtitleTrack> tracks,  List<SubtitleCue> cues,  String? selected,  bool loading,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _SubtitleState():
return $default(_that.tracks,_that.cues,_that.selected,_that.loading,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubtitleTrack> tracks,  List<SubtitleCue> cues,  String? selected,  bool loading,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleState() when $default != null:
return $default(_that.tracks,_that.cues,_that.selected,_that.loading,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleState implements SubtitleState {
  const _SubtitleState({ List<SubtitleTrack> tracks = const <SubtitleTrack>[],  List<SubtitleCue> cues = const <SubtitleCue>[], this.selected, this.loading = false, this.failure}): _tracks = tracks,_cues = cues;
  

 final  List<SubtitleTrack> _tracks;
@override@JsonKey() List<SubtitleTrack> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

 final  List<SubtitleCue> _cues;
@override@JsonKey() List<SubtitleCue> get cues {
  if (_cues is EqualUnmodifiableListView) return _cues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cues);
}

@override final  String? selected;
@override@JsonKey() final  bool loading;
@override final  AppFailure? failure;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleStateCopyWith<_SubtitleState> get copyWith => __$SubtitleStateCopyWithImpl<_SubtitleState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleState&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&const DeepCollectionEquality().equals(other.cues, _cues)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks),const DeepCollectionEquality().hash(_cues),selected,loading,failure);
}

@override
String toString() {
    return 'SubtitleState(tracks: $tracks, cues: $cues, selected: $selected, loading: $loading, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$SubtitleStateCopyWith<$Res> implements $SubtitleStateCopyWith<$Res> {
  factory _$SubtitleStateCopyWith(_SubtitleState value, $Res Function(_SubtitleState) _then) = __$SubtitleStateCopyWithImpl;
@override @useResult
$Res call({
 List<SubtitleTrack> tracks, List<SubtitleCue> cues, String? selected, bool loading, AppFailure? failure
});




}
/// @nodoc
class __$SubtitleStateCopyWithImpl<$Res>
    implements _$SubtitleStateCopyWith<$Res> {
  __$SubtitleStateCopyWithImpl(this._self, this._then);

  final _SubtitleState _self;
  final $Res Function(_SubtitleState) _then;

/// Create a copy of SubtitleState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,Object? cues = null,Object? selected = freezed,Object? loading = null,Object? failure = freezed,}) {
  return _then(_SubtitleState(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,cues: null == cues ? _self._cues : cues // ignore: cast_nullable_to_non_nullable
as List<SubtitleCue>,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

/// @nodoc
mixin _$DanmakuState {

 DanmakuManifest? get manifest; List<DanmakuItem> get items; bool get loading; int get window; AppFailure? get failure;
/// Create a copy of DanmakuState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DanmakuStateCopyWith<DanmakuState> get copyWith => _$DanmakuStateCopyWithImpl<DanmakuState>(this as DanmakuState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DanmakuState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DanmakuState&&(identical(other.manifest, _this.manifest) || other.manifest == _this.manifest)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.window, _this.window) || other.window == _this.window)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as DanmakuState;
  return Object.hash(runtimeType,_this.manifest,const DeepCollectionEquality().hash(_this.items),_this.loading,_this.window,_this.failure);
}

@override
String toString() {
  final _this = this as DanmakuState;
  return 'DanmakuState(manifest: ${_this.manifest}, items: ${_this.items}, loading: ${_this.loading}, window: ${_this.window}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $DanmakuStateCopyWith<$Res>  {
  factory $DanmakuStateCopyWith(DanmakuState value, $Res Function(DanmakuState) _then) = _$DanmakuStateCopyWithImpl;
@useResult
$Res call({
 DanmakuManifest? manifest, List<DanmakuItem> items, bool loading, int window, AppFailure? failure
});




}
/// @nodoc
class _$DanmakuStateCopyWithImpl<$Res>
    implements $DanmakuStateCopyWith<$Res> {
  _$DanmakuStateCopyWithImpl(this._self, this._then);

  final DanmakuState _self;
  final $Res Function(DanmakuState) _then;

/// Create a copy of DanmakuState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? manifest = freezed,Object? items = null,Object? loading = null,Object? window = null,Object? failure = freezed,}) {
  return _then(DanmakuState(
manifest: freezed == manifest ? _self.manifest : manifest // ignore: cast_nullable_to_non_nullable
as DanmakuManifest?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DanmakuItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [DanmakuState].
extension DanmakuStatePatterns on DanmakuState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DanmakuState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DanmakuState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DanmakuState value)  $default,){
final _that = this;
switch (_that) {
case _DanmakuState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DanmakuState value)?  $default,){
final _that = this;
switch (_that) {
case _DanmakuState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DanmakuManifest? manifest,  List<DanmakuItem> items,  bool loading,  int window,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DanmakuState() when $default != null:
return $default(_that.manifest,_that.items,_that.loading,_that.window,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DanmakuManifest? manifest,  List<DanmakuItem> items,  bool loading,  int window,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _DanmakuState():
return $default(_that.manifest,_that.items,_that.loading,_that.window,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DanmakuManifest? manifest,  List<DanmakuItem> items,  bool loading,  int window,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _DanmakuState() when $default != null:
return $default(_that.manifest,_that.items,_that.loading,_that.window,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _DanmakuState implements DanmakuState {
  const _DanmakuState({this.manifest,  List<DanmakuItem> items = const <DanmakuItem>[], this.loading = false, this.window = 0, this.failure}): _items = items;
  

@override final  DanmakuManifest? manifest;
 final  List<DanmakuItem> _items;
@override@JsonKey() List<DanmakuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  int window;
@override final  AppFailure? failure;

/// Create a copy of DanmakuState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DanmakuStateCopyWith<_DanmakuState> get copyWith => __$DanmakuStateCopyWithImpl<_DanmakuState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DanmakuState&&(identical(other.manifest, manifest) || other.manifest == manifest)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.window, window) || other.window == window)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,manifest,const DeepCollectionEquality().hash(_items),loading,window,failure);
}

@override
String toString() {
    return 'DanmakuState(manifest: $manifest, items: $items, loading: $loading, window: $window, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$DanmakuStateCopyWith<$Res> implements $DanmakuStateCopyWith<$Res> {
  factory _$DanmakuStateCopyWith(_DanmakuState value, $Res Function(_DanmakuState) _then) = __$DanmakuStateCopyWithImpl;
@override @useResult
$Res call({
 DanmakuManifest? manifest, List<DanmakuItem> items, bool loading, int window, AppFailure? failure
});




}
/// @nodoc
class __$DanmakuStateCopyWithImpl<$Res>
    implements _$DanmakuStateCopyWith<$Res> {
  __$DanmakuStateCopyWithImpl(this._self, this._then);

  final _DanmakuState _self;
  final $Res Function(_DanmakuState) _then;

/// Create a copy of DanmakuState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? manifest = freezed,Object? items = null,Object? loading = null,Object? window = null,Object? failure = freezed,}) {
  return _then(_DanmakuState(
manifest: freezed == manifest ? _self.manifest : manifest // ignore: cast_nullable_to_non_nullable
as DanmakuManifest?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DanmakuItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as int,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
