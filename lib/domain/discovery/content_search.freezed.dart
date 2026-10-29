// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentSearchItem {

 String get title; String get subtitle; String? get coverUrl;
/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentSearchItemCopyWith<ContentSearchItem> get copyWith => _$ContentSearchItemCopyWithImpl<ContentSearchItem>(this as ContentSearchItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContentSearchItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentSearchItem&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl));
}


@override
int get hashCode {
  final _this = this as ContentSearchItem;
  return Object.hash(runtimeType,_this.title,_this.subtitle,_this.coverUrl);
}

@override
String toString() {
  final _this = this as ContentSearchItem;
  return 'ContentSearchItem(title: ${_this.title}, subtitle: ${_this.subtitle}, coverUrl: ${_this.coverUrl})';
}


}

/// @nodoc
abstract mixin class $ContentSearchItemCopyWith<$Res>  {
  factory $ContentSearchItemCopyWith(ContentSearchItem value, $Res Function(ContentSearchItem) _then) = _$ContentSearchItemCopyWithImpl;
@useResult
$Res call({
 String title, String subtitle, String? coverUrl
});




}
/// @nodoc
class _$ContentSearchItemCopyWithImpl<$Res>
    implements $ContentSearchItemCopyWith<$Res> {
  _$ContentSearchItemCopyWithImpl(this._self, this._then);

  final ContentSearchItem _self;
  final $Res Function(ContentSearchItem) _then;

/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? subtitle = null,Object? coverUrl = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentSearchItem].
extension ContentSearchItemPatterns on ContentSearchItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SeasonSearchItem value)?  season,TResult Function( LiveSearchItem value)?  live,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SeasonSearchItem() when season != null:
return season(_that);case LiveSearchItem() when live != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SeasonSearchItem value)  season,required TResult Function( LiveSearchItem value)  live,}){
final _that = this;
switch (_that) {
case SeasonSearchItem():
return season(_that);case LiveSearchItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SeasonSearchItem value)?  season,TResult? Function( LiveSearchItem value)?  live,}){
final _that = this;
switch (_that) {
case SeasonSearchItem() when season != null:
return season(_that);case LiveSearchItem() when live != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String seasonId,  String title,  String subtitle,  String? coverUrl)?  season,TResult Function( String roomId,  String title,  String subtitle,  bool broadcasting,  String? coverUrl,  String? avatarUrl)?  live,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SeasonSearchItem() when season != null:
return season(_that.seasonId,_that.title,_that.subtitle,_that.coverUrl);case LiveSearchItem() when live != null:
return live(_that.roomId,_that.title,_that.subtitle,_that.broadcasting,_that.coverUrl,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String seasonId,  String title,  String subtitle,  String? coverUrl)  season,required TResult Function( String roomId,  String title,  String subtitle,  bool broadcasting,  String? coverUrl,  String? avatarUrl)  live,}) {final _that = this;
switch (_that) {
case SeasonSearchItem():
return season(_that.seasonId,_that.title,_that.subtitle,_that.coverUrl);case LiveSearchItem():
return live(_that.roomId,_that.title,_that.subtitle,_that.broadcasting,_that.coverUrl,_that.avatarUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String seasonId,  String title,  String subtitle,  String? coverUrl)?  season,TResult? Function( String roomId,  String title,  String subtitle,  bool broadcasting,  String? coverUrl,  String? avatarUrl)?  live,}) {final _that = this;
switch (_that) {
case SeasonSearchItem() when season != null:
return season(_that.seasonId,_that.title,_that.subtitle,_that.coverUrl);case LiveSearchItem() when live != null:
return live(_that.roomId,_that.title,_that.subtitle,_that.broadcasting,_that.coverUrl,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class SeasonSearchItem extends ContentSearchItem {
  const SeasonSearchItem({required this.seasonId, required this.title, required this.subtitle, this.coverUrl}): super._();
  

 final  String seasonId;
@override final  String title;
@override final  String subtitle;
@override final  String? coverUrl;

/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonSearchItemCopyWith<SeasonSearchItem> get copyWith => _$SeasonSearchItemCopyWithImpl<SeasonSearchItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SeasonSearchItem&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,title,subtitle,coverUrl);
}

@override
String toString() {
    return 'ContentSearchItem.season(seasonId: $seasonId, title: $title, subtitle: $subtitle, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $SeasonSearchItemCopyWith<$Res> implements $ContentSearchItemCopyWith<$Res> {
  factory $SeasonSearchItemCopyWith(SeasonSearchItem value, $Res Function(SeasonSearchItem) _then) = _$SeasonSearchItemCopyWithImpl;
@override @useResult
$Res call({
 String seasonId, String title, String subtitle, String? coverUrl
});




}
/// @nodoc
class _$SeasonSearchItemCopyWithImpl<$Res>
    implements $SeasonSearchItemCopyWith<$Res> {
  _$SeasonSearchItemCopyWithImpl(this._self, this._then);

  final SeasonSearchItem _self;
  final $Res Function(SeasonSearchItem) _then;

/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? title = null,Object? subtitle = null,Object? coverUrl = freezed,}) {
  return _then(SeasonSearchItem(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LiveSearchItem extends ContentSearchItem {
  const LiveSearchItem({required this.roomId, required this.title, required this.subtitle, required this.broadcasting, this.coverUrl, this.avatarUrl}): super._();
  

 final  String roomId;
@override final  String title;
@override final  String subtitle;
 final  bool broadcasting;
@override final  String? coverUrl;
 final  String? avatarUrl;

/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveSearchItemCopyWith<LiveSearchItem> get copyWith => _$LiveSearchItemCopyWithImpl<LiveSearchItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveSearchItem&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.broadcasting, broadcasting) || other.broadcasting == broadcasting)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,roomId,title,subtitle,broadcasting,coverUrl,avatarUrl);
}

@override
String toString() {
    return 'ContentSearchItem.live(roomId: $roomId, title: $title, subtitle: $subtitle, broadcasting: $broadcasting, coverUrl: $coverUrl, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $LiveSearchItemCopyWith<$Res> implements $ContentSearchItemCopyWith<$Res> {
  factory $LiveSearchItemCopyWith(LiveSearchItem value, $Res Function(LiveSearchItem) _then) = _$LiveSearchItemCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String title, String subtitle, bool broadcasting, String? coverUrl, String? avatarUrl
});




}
/// @nodoc
class _$LiveSearchItemCopyWithImpl<$Res>
    implements $LiveSearchItemCopyWith<$Res> {
  _$LiveSearchItemCopyWithImpl(this._self, this._then);

  final LiveSearchItem _self;
  final $Res Function(LiveSearchItem) _then;

/// Create a copy of ContentSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? title = null,Object? subtitle = null,Object? broadcasting = null,Object? coverUrl = freezed,Object? avatarUrl = freezed,}) {
  return _then(LiveSearchItem(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,broadcasting: null == broadcasting ? _self.broadcasting : broadcasting // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
