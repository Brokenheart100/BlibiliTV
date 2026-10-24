// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogState {

 List<VideoSummary> get items; String? get nextCursor; bool get refreshing; bool get loadingMore; bool get paused; bool get loadMoreFailed; String? get notice; AppFailure? get failure;
/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStateCopyWith<CatalogState> get copyWith => _$CatalogStateCopyWithImpl<CatalogState>(this as CatalogState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatalogState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.loadMoreFailed, _this.loadMoreFailed) || other.loadMoreFailed == _this.loadMoreFailed)&&(identical(other.notice, _this.notice) || other.notice == _this.notice)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as CatalogState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.refreshing,_this.loadingMore,_this.paused,_this.loadMoreFailed,_this.notice,_this.failure);
}

@override
String toString() {
  final _this = this as CatalogState;
  return 'CatalogState(items: ${_this.items}, nextCursor: ${_this.nextCursor}, refreshing: ${_this.refreshing}, loadingMore: ${_this.loadingMore}, paused: ${_this.paused}, loadMoreFailed: ${_this.loadMoreFailed}, notice: ${_this.notice}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $CatalogStateCopyWith<$Res>  {
  factory $CatalogStateCopyWith(CatalogState value, $Res Function(CatalogState) _then) = _$CatalogStateCopyWithImpl;
@useResult
$Res call({
 List<VideoSummary> items, String? nextCursor, bool refreshing, bool loadingMore, bool paused, bool loadMoreFailed, String? notice, AppFailure? failure
});




}
/// @nodoc
class _$CatalogStateCopyWithImpl<$Res>
    implements $CatalogStateCopyWith<$Res> {
  _$CatalogStateCopyWithImpl(this._self, this._then);

  final CatalogState _self;
  final $Res Function(CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? refreshing = null,Object? loadingMore = null,Object? paused = null,Object? loadMoreFailed = null,Object? notice = freezed,Object? failure = freezed,}) {
  return _then(CatalogState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<VideoSummary>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogState].
extension CatalogStatePatterns on CatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogState value)  $default,){
final _that = this;
switch (_that) {
case _CatalogState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogState value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VideoSummary> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  String? notice,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.notice,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VideoSummary> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  String? notice,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _CatalogState():
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.notice,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VideoSummary> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  String? notice,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.notice,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogState implements CatalogState {
  const _CatalogState({ List<VideoSummary> items = const <VideoSummary>[], this.nextCursor, this.refreshing = false, this.loadingMore = false, this.paused = false, this.loadMoreFailed = false, this.notice, this.failure}): _items = items;
  

 final  List<VideoSummary> _items;
@override@JsonKey() List<VideoSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool refreshing;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  bool loadMoreFailed;
@override final  String? notice;
@override final  AppFailure? failure;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStateCopyWith<_CatalogState> get copyWith => __$CatalogStateCopyWithImpl<_CatalogState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed)&&(identical(other.notice, notice) || other.notice == notice)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,refreshing,loadingMore,paused,loadMoreFailed,notice,failure);
}

@override
String toString() {
    return 'CatalogState(items: $items, nextCursor: $nextCursor, refreshing: $refreshing, loadingMore: $loadingMore, paused: $paused, loadMoreFailed: $loadMoreFailed, notice: $notice, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$CatalogStateCopyWith<$Res> implements $CatalogStateCopyWith<$Res> {
  factory _$CatalogStateCopyWith(_CatalogState value, $Res Function(_CatalogState) _then) = __$CatalogStateCopyWithImpl;
@override @useResult
$Res call({
 List<VideoSummary> items, String? nextCursor, bool refreshing, bool loadingMore, bool paused, bool loadMoreFailed, String? notice, AppFailure? failure
});




}
/// @nodoc
class __$CatalogStateCopyWithImpl<$Res>
    implements _$CatalogStateCopyWith<$Res> {
  __$CatalogStateCopyWithImpl(this._self, this._then);

  final _CatalogState _self;
  final $Res Function(_CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? refreshing = null,Object? loadingMore = null,Object? paused = null,Object? loadMoreFailed = null,Object? notice = freezed,Object? failure = freezed,}) {
  return _then(_CatalogState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VideoSummary>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
