// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overlays.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubtitleTrack {

 String get id; String get language; String get title; bool get ai;
/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<SubtitleTrack> get copyWith => _$SubtitleTrackCopyWithImpl<SubtitleTrack>(this as SubtitleTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubtitleTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.ai, _this.ai) || other.ai == _this.ai));
}


@override
int get hashCode {
  final _this = this as SubtitleTrack;
  return Object.hash(runtimeType,_this.id,_this.language,_this.title,_this.ai);
}

@override
String toString() {
  final _this = this as SubtitleTrack;
  return 'SubtitleTrack(id: ${_this.id}, language: ${_this.language}, title: ${_this.title}, ai: ${_this.ai})';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackCopyWith<$Res>  {
  factory $SubtitleTrackCopyWith(SubtitleTrack value, $Res Function(SubtitleTrack) _then) = _$SubtitleTrackCopyWithImpl;
@useResult
$Res call({
 String id, String language, String title, bool ai
});




}
/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._self, this._then);

  final SubtitleTrack _self;
  final $Res Function(SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? title = null,Object? ai = null,}) {
  return _then(SubtitleTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ai: null == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrack].
extension SubtitleTrackPatterns on SubtitleTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrack value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrack value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String language,  String title,  bool ai)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.language,_that.title,_that.ai);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String language,  String title,  bool ai)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack():
return $default(_that.id,_that.language,_that.title,_that.ai);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String language,  String title,  bool ai)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.language,_that.title,_that.ai);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleTrack implements SubtitleTrack {
  const _SubtitleTrack({required this.id, required this.language, required this.title, this.ai = false});
  

@override final  String id;
@override final  String language;
@override final  String title;
@override@JsonKey() final  bool ai;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackCopyWith<_SubtitleTrack> get copyWith => __$SubtitleTrackCopyWithImpl<_SubtitleTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.title, title) || other.title == title)&&(identical(other.ai, ai) || other.ai == ai));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,language,title,ai);
}

@override
String toString() {
    return 'SubtitleTrack(id: $id, language: $language, title: $title, ai: $ai)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackCopyWith<$Res> implements $SubtitleTrackCopyWith<$Res> {
  factory _$SubtitleTrackCopyWith(_SubtitleTrack value, $Res Function(_SubtitleTrack) _then) = __$SubtitleTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String language, String title, bool ai
});




}
/// @nodoc
class __$SubtitleTrackCopyWithImpl<$Res>
    implements _$SubtitleTrackCopyWith<$Res> {
  __$SubtitleTrackCopyWithImpl(this._self, this._then);

  final _SubtitleTrack _self;
  final $Res Function(_SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? title = null,Object? ai = null,}) {
  return _then(_SubtitleTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ai: null == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SubtitleCue {

 int get startMs; int get endMs; String get text;
/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleCueCopyWith<SubtitleCue> get copyWith => _$SubtitleCueCopyWithImpl<SubtitleCue>(this as SubtitleCue, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubtitleCue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleCue&&(identical(other.startMs, _this.startMs) || other.startMs == _this.startMs)&&(identical(other.endMs, _this.endMs) || other.endMs == _this.endMs)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as SubtitleCue;
  return Object.hash(runtimeType,_this.startMs,_this.endMs,_this.text);
}



}

/// @nodoc
abstract mixin class $SubtitleCueCopyWith<$Res>  {
  factory $SubtitleCueCopyWith(SubtitleCue value, $Res Function(SubtitleCue) _then) = _$SubtitleCueCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, String text
});




}
/// @nodoc
class _$SubtitleCueCopyWithImpl<$Res>
    implements $SubtitleCueCopyWith<$Res> {
  _$SubtitleCueCopyWithImpl(this._self, this._then);

  final SubtitleCue _self;
  final $Res Function(SubtitleCue) _then;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startMs = null,Object? endMs = null,Object? text = null,}) {
  return _then(SubtitleCue(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleCue].
extension SubtitleCuePatterns on SubtitleCue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleCue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleCue value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleCue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleCue value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int startMs,  int endMs,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
return $default(_that.startMs,_that.endMs,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int startMs,  int endMs,  String text)  $default,) {final _that = this;
switch (_that) {
case _SubtitleCue():
return $default(_that.startMs,_that.endMs,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int startMs,  int endMs,  String text)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
return $default(_that.startMs,_that.endMs,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleCue implements SubtitleCue {
  const _SubtitleCue({required this.startMs, required this.endMs, required this.text});
  

@override final  int startMs;
@override final  int endMs;
@override final  String text;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleCueCopyWith<_SubtitleCue> get copyWith => __$SubtitleCueCopyWithImpl<_SubtitleCue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleCue&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,text);
}



}

/// @nodoc
abstract mixin class _$SubtitleCueCopyWith<$Res> implements $SubtitleCueCopyWith<$Res> {
  factory _$SubtitleCueCopyWith(_SubtitleCue value, $Res Function(_SubtitleCue) _then) = __$SubtitleCueCopyWithImpl;
@override @useResult
$Res call({
 int startMs, int endMs, String text
});




}
/// @nodoc
class __$SubtitleCueCopyWithImpl<$Res>
    implements _$SubtitleCueCopyWith<$Res> {
  __$SubtitleCueCopyWithImpl(this._self, this._then);

  final _SubtitleCue _self;
  final $Res Function(_SubtitleCue) _then;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? text = null,}) {
  return _then(_SubtitleCue(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DanmakuItem {

 String get id; int get timeMs; int get mode; int get color; String get text;
/// Create a copy of DanmakuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DanmakuItemCopyWith<DanmakuItem> get copyWith => _$DanmakuItemCopyWithImpl<DanmakuItem>(this as DanmakuItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DanmakuItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DanmakuItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.timeMs, _this.timeMs) || other.timeMs == _this.timeMs)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as DanmakuItem;
  return Object.hash(runtimeType,_this.id,_this.timeMs,_this.mode,_this.color,_this.text);
}



}

/// @nodoc
abstract mixin class $DanmakuItemCopyWith<$Res>  {
  factory $DanmakuItemCopyWith(DanmakuItem value, $Res Function(DanmakuItem) _then) = _$DanmakuItemCopyWithImpl;
@useResult
$Res call({
 String id, int timeMs, int mode, int color, String text
});




}
/// @nodoc
class _$DanmakuItemCopyWithImpl<$Res>
    implements $DanmakuItemCopyWith<$Res> {
  _$DanmakuItemCopyWithImpl(this._self, this._then);

  final DanmakuItem _self;
  final $Res Function(DanmakuItem) _then;

/// Create a copy of DanmakuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timeMs = null,Object? mode = null,Object? color = null,Object? text = null,}) {
  return _then(DanmakuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeMs: null == timeMs ? _self.timeMs : timeMs // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DanmakuItem].
extension DanmakuItemPatterns on DanmakuItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DanmakuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DanmakuItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DanmakuItem value)  $default,){
final _that = this;
switch (_that) {
case _DanmakuItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DanmakuItem value)?  $default,){
final _that = this;
switch (_that) {
case _DanmakuItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int timeMs,  int mode,  int color,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DanmakuItem() when $default != null:
return $default(_that.id,_that.timeMs,_that.mode,_that.color,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int timeMs,  int mode,  int color,  String text)  $default,) {final _that = this;
switch (_that) {
case _DanmakuItem():
return $default(_that.id,_that.timeMs,_that.mode,_that.color,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int timeMs,  int mode,  int color,  String text)?  $default,) {final _that = this;
switch (_that) {
case _DanmakuItem() when $default != null:
return $default(_that.id,_that.timeMs,_that.mode,_that.color,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _DanmakuItem implements DanmakuItem {
  const _DanmakuItem({required this.id, required this.timeMs, required this.mode, required this.color, required this.text});
  

@override final  String id;
@override final  int timeMs;
@override final  int mode;
@override final  int color;
@override final  String text;

/// Create a copy of DanmakuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DanmakuItemCopyWith<_DanmakuItem> get copyWith => __$DanmakuItemCopyWithImpl<_DanmakuItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DanmakuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.timeMs, timeMs) || other.timeMs == timeMs)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.color, color) || other.color == color)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,timeMs,mode,color,text);
}



}

/// @nodoc
abstract mixin class _$DanmakuItemCopyWith<$Res> implements $DanmakuItemCopyWith<$Res> {
  factory _$DanmakuItemCopyWith(_DanmakuItem value, $Res Function(_DanmakuItem) _then) = __$DanmakuItemCopyWithImpl;
@override @useResult
$Res call({
 String id, int timeMs, int mode, int color, String text
});




}
/// @nodoc
class __$DanmakuItemCopyWithImpl<$Res>
    implements _$DanmakuItemCopyWith<$Res> {
  __$DanmakuItemCopyWithImpl(this._self, this._then);

  final _DanmakuItem _self;
  final $Res Function(_DanmakuItem) _then;

/// Create a copy of DanmakuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timeMs = null,Object? mode = null,Object? color = null,Object? text = null,}) {
  return _then(_DanmakuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeMs: null == timeMs ? _self.timeMs : timeMs // ignore: cast_nullable_to_non_nullable
as int,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as int,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$OverlayPreferences {

 bool get subtitles; String get language; double get fontSize; double get subtitleBottom; int get offsetMs; bool get danmaku; double get opacity; double get area; int get density; bool get top; bool get bottom; bool get scroll; List<String> get keywords;
/// Create a copy of OverlayPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverlayPreferencesCopyWith<OverlayPreferences> get copyWith => _$OverlayPreferencesCopyWithImpl<OverlayPreferences>(this as OverlayPreferences, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OverlayPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverlayPreferences&&(identical(other.subtitles, _this.subtitles) || other.subtitles == _this.subtitles)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.fontSize, _this.fontSize) || other.fontSize == _this.fontSize)&&(identical(other.subtitleBottom, _this.subtitleBottom) || other.subtitleBottom == _this.subtitleBottom)&&(identical(other.offsetMs, _this.offsetMs) || other.offsetMs == _this.offsetMs)&&(identical(other.danmaku, _this.danmaku) || other.danmaku == _this.danmaku)&&(identical(other.opacity, _this.opacity) || other.opacity == _this.opacity)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.density, _this.density) || other.density == _this.density)&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.bottom, _this.bottom) || other.bottom == _this.bottom)&&(identical(other.scroll, _this.scroll) || other.scroll == _this.scroll)&&const DeepCollectionEquality().equals(other.keywords, _this.keywords));
}


@override
int get hashCode {
  final _this = this as OverlayPreferences;
  return Object.hash(runtimeType,_this.subtitles,_this.language,_this.fontSize,_this.subtitleBottom,_this.offsetMs,_this.danmaku,_this.opacity,_this.area,_this.density,_this.top,_this.bottom,_this.scroll,const DeepCollectionEquality().hash(_this.keywords));
}

@override
String toString() {
  final _this = this as OverlayPreferences;
  return 'OverlayPreferences(subtitles: ${_this.subtitles}, language: ${_this.language}, fontSize: ${_this.fontSize}, subtitleBottom: ${_this.subtitleBottom}, offsetMs: ${_this.offsetMs}, danmaku: ${_this.danmaku}, opacity: ${_this.opacity}, area: ${_this.area}, density: ${_this.density}, top: ${_this.top}, bottom: ${_this.bottom}, scroll: ${_this.scroll}, keywords: ${_this.keywords})';
}


}

/// @nodoc
abstract mixin class $OverlayPreferencesCopyWith<$Res>  {
  factory $OverlayPreferencesCopyWith(OverlayPreferences value, $Res Function(OverlayPreferences) _then) = _$OverlayPreferencesCopyWithImpl;
@useResult
$Res call({
 bool subtitles, String language, double fontSize, double subtitleBottom, int offsetMs, bool danmaku, double opacity, double area, int density, bool top, bool bottom, bool scroll, List<String> keywords
});




}
/// @nodoc
class _$OverlayPreferencesCopyWithImpl<$Res>
    implements $OverlayPreferencesCopyWith<$Res> {
  _$OverlayPreferencesCopyWithImpl(this._self, this._then);

  final OverlayPreferences _self;
  final $Res Function(OverlayPreferences) _then;

/// Create a copy of OverlayPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtitles = null,Object? language = null,Object? fontSize = null,Object? subtitleBottom = null,Object? offsetMs = null,Object? danmaku = null,Object? opacity = null,Object? area = null,Object? density = null,Object? top = null,Object? bottom = null,Object? scroll = null,Object? keywords = null,}) {
  return _then(OverlayPreferences(
subtitles: null == subtitles ? _self.subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,subtitleBottom: null == subtitleBottom ? _self.subtitleBottom : subtitleBottom // ignore: cast_nullable_to_non_nullable
as double,offsetMs: null == offsetMs ? _self.offsetMs : offsetMs // ignore: cast_nullable_to_non_nullable
as int,danmaku: null == danmaku ? _self.danmaku : danmaku // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double,density: null == density ? _self.density : density // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as bool,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as bool,scroll: null == scroll ? _self.scroll : scroll // ignore: cast_nullable_to_non_nullable
as bool,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OverlayPreferences].
extension OverlayPreferencesPatterns on OverlayPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverlayPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverlayPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverlayPreferences value)  $default,){
final _that = this;
switch (_that) {
case _OverlayPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverlayPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _OverlayPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool subtitles,  String language,  double fontSize,  double subtitleBottom,  int offsetMs,  bool danmaku,  double opacity,  double area,  int density,  bool top,  bool bottom,  bool scroll,  List<String> keywords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverlayPreferences() when $default != null:
return $default(_that.subtitles,_that.language,_that.fontSize,_that.subtitleBottom,_that.offsetMs,_that.danmaku,_that.opacity,_that.area,_that.density,_that.top,_that.bottom,_that.scroll,_that.keywords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool subtitles,  String language,  double fontSize,  double subtitleBottom,  int offsetMs,  bool danmaku,  double opacity,  double area,  int density,  bool top,  bool bottom,  bool scroll,  List<String> keywords)  $default,) {final _that = this;
switch (_that) {
case _OverlayPreferences():
return $default(_that.subtitles,_that.language,_that.fontSize,_that.subtitleBottom,_that.offsetMs,_that.danmaku,_that.opacity,_that.area,_that.density,_that.top,_that.bottom,_that.scroll,_that.keywords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool subtitles,  String language,  double fontSize,  double subtitleBottom,  int offsetMs,  bool danmaku,  double opacity,  double area,  int density,  bool top,  bool bottom,  bool scroll,  List<String> keywords)?  $default,) {final _that = this;
switch (_that) {
case _OverlayPreferences() when $default != null:
return $default(_that.subtitles,_that.language,_that.fontSize,_that.subtitleBottom,_that.offsetMs,_that.danmaku,_that.opacity,_that.area,_that.density,_that.top,_that.bottom,_that.scroll,_that.keywords);case _:
  return null;

}
}

}

/// @nodoc


class _OverlayPreferences implements OverlayPreferences {
  const _OverlayPreferences({this.subtitles = true, this.language = 'zh', this.fontSize = 24.0, this.subtitleBottom = 45.0, this.offsetMs = 0, this.danmaku = false, this.opacity = .8, this.area = .5, this.density = 40, this.top = true, this.bottom = true, this.scroll = true,  List<String> keywords = const <String>[]}): _keywords = keywords;
  

@override@JsonKey() final  bool subtitles;
@override@JsonKey() final  String language;
@override@JsonKey() final  double fontSize;
@override@JsonKey() final  double subtitleBottom;
@override@JsonKey() final  int offsetMs;
@override@JsonKey() final  bool danmaku;
@override@JsonKey() final  double opacity;
@override@JsonKey() final  double area;
@override@JsonKey() final  int density;
@override@JsonKey() final  bool top;
@override@JsonKey() final  bool bottom;
@override@JsonKey() final  bool scroll;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}


/// Create a copy of OverlayPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverlayPreferencesCopyWith<_OverlayPreferences> get copyWith => __$OverlayPreferencesCopyWithImpl<_OverlayPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverlayPreferences&&(identical(other.subtitles, subtitles) || other.subtitles == subtitles)&&(identical(other.language, language) || other.language == language)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.subtitleBottom, subtitleBottom) || other.subtitleBottom == subtitleBottom)&&(identical(other.offsetMs, offsetMs) || other.offsetMs == offsetMs)&&(identical(other.danmaku, danmaku) || other.danmaku == danmaku)&&(identical(other.opacity, opacity) || other.opacity == opacity)&&(identical(other.area, area) || other.area == area)&&(identical(other.density, density) || other.density == density)&&(identical(other.top, top) || other.top == top)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.scroll, scroll) || other.scroll == scroll)&&const DeepCollectionEquality().equals(other.keywords, _keywords));
}


@override
int get hashCode {
    return Object.hash(runtimeType,subtitles,language,fontSize,subtitleBottom,offsetMs,danmaku,opacity,area,density,top,bottom,scroll,const DeepCollectionEquality().hash(_keywords));
}

@override
String toString() {
    return 'OverlayPreferences(subtitles: $subtitles, language: $language, fontSize: $fontSize, subtitleBottom: $subtitleBottom, offsetMs: $offsetMs, danmaku: $danmaku, opacity: $opacity, area: $area, density: $density, top: $top, bottom: $bottom, scroll: $scroll, keywords: $keywords)';
}


}

/// @nodoc
abstract mixin class _$OverlayPreferencesCopyWith<$Res> implements $OverlayPreferencesCopyWith<$Res> {
  factory _$OverlayPreferencesCopyWith(_OverlayPreferences value, $Res Function(_OverlayPreferences) _then) = __$OverlayPreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool subtitles, String language, double fontSize, double subtitleBottom, int offsetMs, bool danmaku, double opacity, double area, int density, bool top, bool bottom, bool scroll, List<String> keywords
});




}
/// @nodoc
class __$OverlayPreferencesCopyWithImpl<$Res>
    implements _$OverlayPreferencesCopyWith<$Res> {
  __$OverlayPreferencesCopyWithImpl(this._self, this._then);

  final _OverlayPreferences _self;
  final $Res Function(_OverlayPreferences) _then;

/// Create a copy of OverlayPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtitles = null,Object? language = null,Object? fontSize = null,Object? subtitleBottom = null,Object? offsetMs = null,Object? danmaku = null,Object? opacity = null,Object? area = null,Object? density = null,Object? top = null,Object? bottom = null,Object? scroll = null,Object? keywords = null,}) {
  return _then(_OverlayPreferences(
subtitles: null == subtitles ? _self.subtitles : subtitles // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,subtitleBottom: null == subtitleBottom ? _self.subtitleBottom : subtitleBottom // ignore: cast_nullable_to_non_nullable
as double,offsetMs: null == offsetMs ? _self.offsetMs : offsetMs // ignore: cast_nullable_to_non_nullable
as int,danmaku: null == danmaku ? _self.danmaku : danmaku // ignore: cast_nullable_to_non_nullable
as bool,opacity: null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double,density: null == density ? _self.density : density // ignore: cast_nullable_to_non_nullable
as int,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as bool,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as bool,scroll: null == scroll ? _self.scroll : scroll // ignore: cast_nullable_to_non_nullable
as bool,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
