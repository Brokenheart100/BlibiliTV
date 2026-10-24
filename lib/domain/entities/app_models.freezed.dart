// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Session {

 String get ownerKey; String? get displayName; SessionStatus get status; int get generation; String? get notice;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Session;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.ownerKey, _this.ownerKey) || other.ownerKey == _this.ownerKey)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.generation, _this.generation) || other.generation == _this.generation)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as Session;
  return Object.hash(runtimeType,_this.ownerKey,_this.displayName,_this.status,_this.generation,_this.notice);
}

@override
String toString() {
  final _this = this as Session;
  return 'Session(ownerKey: ${_this.ownerKey}, displayName: ${_this.displayName}, status: ${_this.status}, generation: ${_this.generation}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String ownerKey, String? displayName, SessionStatus status, int generation, String? notice
});




}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerKey = null,Object? displayName = freezed,Object? status = null,Object? generation = null,Object? notice = freezed,}) {
  return _then(Session(
ownerKey: null == ownerKey ? _self.ownerKey : ownerKey // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ownerKey,  String? displayName,  SessionStatus status,  int generation,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.ownerKey,_that.displayName,_that.status,_that.generation,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ownerKey,  String? displayName,  SessionStatus status,  int generation,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.ownerKey,_that.displayName,_that.status,_that.generation,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ownerKey,  String? displayName,  SessionStatus status,  int generation,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.ownerKey,_that.displayName,_that.status,_that.generation,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _Session extends Session {
  const _Session({this.ownerKey = 'guest', this.displayName, this.status = SessionStatus.anonymous, this.generation = 0, this.notice}): super._();
  

@override@JsonKey() final  String ownerKey;
@override final  String? displayName;
@override@JsonKey() final  SessionStatus status;
@override@JsonKey() final  int generation;
@override final  String? notice;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.ownerKey, ownerKey) || other.ownerKey == ownerKey)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ownerKey,displayName,status,generation,notice);
}

@override
String toString() {
    return 'Session(ownerKey: $ownerKey, displayName: $displayName, status: $status, generation: $generation, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String ownerKey, String? displayName, SessionStatus status, int generation, String? notice
});




}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerKey = null,Object? displayName = freezed,Object? status = null,Object? generation = null,Object? notice = freezed,}) {
  return _then(_Session(
ownerKey: null == ownerKey ? _self.ownerKey : ownerKey // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$VideoSummary {

 String get id; String get title; String get creator; int get durationSeconds; int get viewCount; String? get coverUrl;
/// Create a copy of VideoSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoSummaryCopyWith<VideoSummary> get copyWith => _$VideoSummaryCopyWithImpl<VideoSummary>(this as VideoSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.creator, _this.creator) || other.creator == _this.creator)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.viewCount, _this.viewCount) || other.viewCount == _this.viewCount)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl));
}


@override
int get hashCode {
  final _this = this as VideoSummary;
  return Object.hash(runtimeType,_this.id,_this.title,_this.creator,_this.durationSeconds,_this.viewCount,_this.coverUrl);
}

@override
String toString() {
  final _this = this as VideoSummary;
  return 'VideoSummary(id: ${_this.id}, title: ${_this.title}, creator: ${_this.creator}, durationSeconds: ${_this.durationSeconds}, viewCount: ${_this.viewCount}, coverUrl: ${_this.coverUrl})';
}


}

/// @nodoc
abstract mixin class $VideoSummaryCopyWith<$Res>  {
  factory $VideoSummaryCopyWith(VideoSummary value, $Res Function(VideoSummary) _then) = _$VideoSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String creator, int durationSeconds, int viewCount, String? coverUrl
});




}
/// @nodoc
class _$VideoSummaryCopyWithImpl<$Res>
    implements $VideoSummaryCopyWith<$Res> {
  _$VideoSummaryCopyWithImpl(this._self, this._then);

  final VideoSummary _self;
  final $Res Function(VideoSummary) _then;

/// Create a copy of VideoSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? creator = null,Object? durationSeconds = null,Object? viewCount = null,Object? coverUrl = freezed,}) {
  return _then(VideoSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoSummary].
extension VideoSummaryPatterns on VideoSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoSummary value)  $default,){
final _that = this;
switch (_that) {
case _VideoSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoSummary value)?  $default,){
final _that = this;
switch (_that) {
case _VideoSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String creator,  int durationSeconds,  int viewCount,  String? coverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoSummary() when $default != null:
return $default(_that.id,_that.title,_that.creator,_that.durationSeconds,_that.viewCount,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String creator,  int durationSeconds,  int viewCount,  String? coverUrl)  $default,) {final _that = this;
switch (_that) {
case _VideoSummary():
return $default(_that.id,_that.title,_that.creator,_that.durationSeconds,_that.viewCount,_that.coverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String creator,  int durationSeconds,  int viewCount,  String? coverUrl)?  $default,) {final _that = this;
switch (_that) {
case _VideoSummary() when $default != null:
return $default(_that.id,_that.title,_that.creator,_that.durationSeconds,_that.viewCount,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc


class _VideoSummary implements VideoSummary {
  const _VideoSummary({required this.id, required this.title, required this.creator, required this.durationSeconds, required this.viewCount, this.coverUrl});
  

@override final  String id;
@override final  String title;
@override final  String creator;
@override final  int durationSeconds;
@override final  int viewCount;
@override final  String? coverUrl;

/// Create a copy of VideoSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoSummaryCopyWith<_VideoSummary> get copyWith => __$VideoSummaryCopyWithImpl<_VideoSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,creator,durationSeconds,viewCount,coverUrl);
}

@override
String toString() {
    return 'VideoSummary(id: $id, title: $title, creator: $creator, durationSeconds: $durationSeconds, viewCount: $viewCount, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class _$VideoSummaryCopyWith<$Res> implements $VideoSummaryCopyWith<$Res> {
  factory _$VideoSummaryCopyWith(_VideoSummary value, $Res Function(_VideoSummary) _then) = __$VideoSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String creator, int durationSeconds, int viewCount, String? coverUrl
});




}
/// @nodoc
class __$VideoSummaryCopyWithImpl<$Res>
    implements _$VideoSummaryCopyWith<$Res> {
  __$VideoSummaryCopyWithImpl(this._self, this._then);

  final _VideoSummary _self;
  final $Res Function(_VideoSummary) _then;

/// Create a copy of VideoSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? creator = null,Object? durationSeconds = null,Object? viewCount = null,Object? coverUrl = freezed,}) {
  return _then(_VideoSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$VideoPart {

 String get id; String get title; int get durationSeconds;
/// Create a copy of VideoPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoPartCopyWith<VideoPart> get copyWith => _$VideoPartCopyWithImpl<VideoPart>(this as VideoPart, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoPart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoPart&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds));
}


@override
int get hashCode {
  final _this = this as VideoPart;
  return Object.hash(runtimeType,_this.id,_this.title,_this.durationSeconds);
}

@override
String toString() {
  final _this = this as VideoPart;
  return 'VideoPart(id: ${_this.id}, title: ${_this.title}, durationSeconds: ${_this.durationSeconds})';
}


}

/// @nodoc
abstract mixin class $VideoPartCopyWith<$Res>  {
  factory $VideoPartCopyWith(VideoPart value, $Res Function(VideoPart) _then) = _$VideoPartCopyWithImpl;
@useResult
$Res call({
 String id, String title, int durationSeconds
});




}
/// @nodoc
class _$VideoPartCopyWithImpl<$Res>
    implements $VideoPartCopyWith<$Res> {
  _$VideoPartCopyWithImpl(this._self, this._then);

  final VideoPart _self;
  final $Res Function(VideoPart) _then;

/// Create a copy of VideoPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? durationSeconds = null,}) {
  return _then(VideoPart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoPart].
extension VideoPartPatterns on VideoPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoPart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoPart value)  $default,){
final _that = this;
switch (_that) {
case _VideoPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoPart value)?  $default,){
final _that = this;
switch (_that) {
case _VideoPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoPart() when $default != null:
return $default(_that.id,_that.title,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _VideoPart():
return $default(_that.id,_that.title,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _VideoPart() when $default != null:
return $default(_that.id,_that.title,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _VideoPart implements VideoPart {
  const _VideoPart({required this.id, required this.title, this.durationSeconds = 0});
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  int durationSeconds;

/// Create a copy of VideoPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoPartCopyWith<_VideoPart> get copyWith => __$VideoPartCopyWithImpl<_VideoPart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoPart&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,durationSeconds);
}

@override
String toString() {
    return 'VideoPart(id: $id, title: $title, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$VideoPartCopyWith<$Res> implements $VideoPartCopyWith<$Res> {
  factory _$VideoPartCopyWith(_VideoPart value, $Res Function(_VideoPart) _then) = __$VideoPartCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int durationSeconds
});




}
/// @nodoc
class __$VideoPartCopyWithImpl<$Res>
    implements _$VideoPartCopyWith<$Res> {
  __$VideoPartCopyWithImpl(this._self, this._then);

  final _VideoPart _self;
  final $Res Function(_VideoPart) _then;

/// Create a copy of VideoPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? durationSeconds = null,}) {
  return _then(_VideoPart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$VideoDetail {

 VideoSummary get video; List<VideoPart> get parts; String get description; String? get creatorAvatarUrl; int get creatorId;
/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoDetailCopyWith<VideoDetail> get copyWith => _$VideoDetailCopyWithImpl<VideoDetail>(this as VideoDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoDetail&&(identical(other.video, _this.video) || other.video == _this.video)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.creatorAvatarUrl, _this.creatorAvatarUrl) || other.creatorAvatarUrl == _this.creatorAvatarUrl)&&(identical(other.creatorId, _this.creatorId) || other.creatorId == _this.creatorId));
}


@override
int get hashCode {
  final _this = this as VideoDetail;
  return Object.hash(runtimeType,_this.video,const DeepCollectionEquality().hash(_this.parts),_this.description,_this.creatorAvatarUrl,_this.creatorId);
}

@override
String toString() {
  final _this = this as VideoDetail;
  return 'VideoDetail(video: ${_this.video}, parts: ${_this.parts}, description: ${_this.description}, creatorAvatarUrl: ${_this.creatorAvatarUrl}, creatorId: ${_this.creatorId})';
}


}

/// @nodoc
abstract mixin class $VideoDetailCopyWith<$Res>  {
  factory $VideoDetailCopyWith(VideoDetail value, $Res Function(VideoDetail) _then) = _$VideoDetailCopyWithImpl;
@useResult
$Res call({
 VideoSummary video, List<VideoPart> parts, String description, String? creatorAvatarUrl, int creatorId
});


$VideoSummaryCopyWith<$Res> get video;

}
/// @nodoc
class _$VideoDetailCopyWithImpl<$Res>
    implements $VideoDetailCopyWith<$Res> {
  _$VideoDetailCopyWithImpl(this._self, this._then);

  final VideoDetail _self;
  final $Res Function(VideoDetail) _then;

/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? video = null,Object? parts = null,Object? description = null,Object? creatorAvatarUrl = freezed,Object? creatorId = null,}) {
  return _then(VideoDetail(
video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as VideoSummary,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<VideoPart>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,creatorAvatarUrl: freezed == creatorAvatarUrl ? _self.creatorAvatarUrl : creatorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoSummaryCopyWith<$Res> get video {
  
  return $VideoSummaryCopyWith<$Res>(_self.video, (value) {
    return _then(_self.copyWith(video: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoDetail].
extension VideoDetailPatterns on VideoDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoDetail value)  $default,){
final _that = this;
switch (_that) {
case _VideoDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoDetail value)?  $default,){
final _that = this;
switch (_that) {
case _VideoDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VideoSummary video,  List<VideoPart> parts,  String description,  String? creatorAvatarUrl,  int creatorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoDetail() when $default != null:
return $default(_that.video,_that.parts,_that.description,_that.creatorAvatarUrl,_that.creatorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VideoSummary video,  List<VideoPart> parts,  String description,  String? creatorAvatarUrl,  int creatorId)  $default,) {final _that = this;
switch (_that) {
case _VideoDetail():
return $default(_that.video,_that.parts,_that.description,_that.creatorAvatarUrl,_that.creatorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VideoSummary video,  List<VideoPart> parts,  String description,  String? creatorAvatarUrl,  int creatorId)?  $default,) {final _that = this;
switch (_that) {
case _VideoDetail() when $default != null:
return $default(_that.video,_that.parts,_that.description,_that.creatorAvatarUrl,_that.creatorId);case _:
  return null;

}
}

}

/// @nodoc


class _VideoDetail implements VideoDetail {
  const _VideoDetail({required this.video, required  List<VideoPart> parts, required this.description, this.creatorAvatarUrl, this.creatorId = 0}): _parts = parts;
  

@override final  VideoSummary video;
 final  List<VideoPart> _parts;
@override List<VideoPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

@override final  String description;
@override final  String? creatorAvatarUrl;
@override@JsonKey() final  int creatorId;

/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoDetailCopyWith<_VideoDetail> get copyWith => __$VideoDetailCopyWithImpl<_VideoDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoDetail&&(identical(other.video, video) || other.video == video)&&const DeepCollectionEquality().equals(other.parts, _parts)&&(identical(other.description, description) || other.description == description)&&(identical(other.creatorAvatarUrl, creatorAvatarUrl) || other.creatorAvatarUrl == creatorAvatarUrl)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,video,const DeepCollectionEquality().hash(_parts),description,creatorAvatarUrl,creatorId);
}

@override
String toString() {
    return 'VideoDetail(video: $video, parts: $parts, description: $description, creatorAvatarUrl: $creatorAvatarUrl, creatorId: $creatorId)';
}


}

/// @nodoc
abstract mixin class _$VideoDetailCopyWith<$Res> implements $VideoDetailCopyWith<$Res> {
  factory _$VideoDetailCopyWith(_VideoDetail value, $Res Function(_VideoDetail) _then) = __$VideoDetailCopyWithImpl;
@override @useResult
$Res call({
 VideoSummary video, List<VideoPart> parts, String description, String? creatorAvatarUrl, int creatorId
});


@override $VideoSummaryCopyWith<$Res> get video;

}
/// @nodoc
class __$VideoDetailCopyWithImpl<$Res>
    implements _$VideoDetailCopyWith<$Res> {
  __$VideoDetailCopyWithImpl(this._self, this._then);

  final _VideoDetail _self;
  final $Res Function(_VideoDetail) _then;

/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? video = null,Object? parts = null,Object? description = null,Object? creatorAvatarUrl = freezed,Object? creatorId = null,}) {
  return _then(_VideoDetail(
video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as VideoSummary,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<VideoPart>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,creatorAvatarUrl: freezed == creatorAvatarUrl ? _self.creatorAvatarUrl : creatorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of VideoDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoSummaryCopyWith<$Res> get video {
  
  return $VideoSummaryCopyWith<$Res>(_self.video, (value) {
    return _then(_self.copyWith(video: value));
  });
}
}

/// @nodoc
mixin _$AppSettings {

 bool get reducedMotion; bool get resumePlayback;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.reducedMotion, _this.reducedMotion) || other.reducedMotion == _this.reducedMotion)&&(identical(other.resumePlayback, _this.resumePlayback) || other.resumePlayback == _this.resumePlayback));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.reducedMotion,_this.resumePlayback);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(reducedMotion: ${_this.reducedMotion}, resumePlayback: ${_this.resumePlayback})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 bool reducedMotion, bool resumePlayback
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reducedMotion = null,Object? resumePlayback = null,}) {
  return _then(AppSettings(
reducedMotion: null == reducedMotion ? _self.reducedMotion : reducedMotion // ignore: cast_nullable_to_non_nullable
as bool,resumePlayback: null == resumePlayback ? _self.resumePlayback : resumePlayback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool reducedMotion,  bool resumePlayback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.reducedMotion,_that.resumePlayback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool reducedMotion,  bool resumePlayback)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.reducedMotion,_that.resumePlayback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool reducedMotion,  bool resumePlayback)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.reducedMotion,_that.resumePlayback);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.reducedMotion = false, this.resumePlayback = true});
  

@override@JsonKey() final  bool reducedMotion;
@override@JsonKey() final  bool resumePlayback;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.reducedMotion, reducedMotion) || other.reducedMotion == reducedMotion)&&(identical(other.resumePlayback, resumePlayback) || other.resumePlayback == resumePlayback));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reducedMotion,resumePlayback);
}

@override
String toString() {
    return 'AppSettings(reducedMotion: $reducedMotion, resumePlayback: $resumePlayback)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool reducedMotion, bool resumePlayback
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reducedMotion = null,Object? resumePlayback = null,}) {
  return _then(_AppSettings(
reducedMotion: null == reducedMotion ? _self.reducedMotion : reducedMotion // ignore: cast_nullable_to_non_nullable
as bool,resumePlayback: null == resumePlayback ? _self.resumePlayback : resumePlayback // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
