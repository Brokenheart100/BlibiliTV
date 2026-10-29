// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_search_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentSearchState {

 List<ContentSearchItem> get items; String? get nextCursor; bool get refreshing; bool get loadingMore; bool get paused; bool get loadMoreFailed; AppFailure? get failure;
/// Create a copy of ContentSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentSearchStateCopyWith<ContentSearchState> get copyWith => _$ContentSearchStateCopyWithImpl<ContentSearchState>(this as ContentSearchState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContentSearchState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentSearchState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.loadMoreFailed, _this.loadMoreFailed) || other.loadMoreFailed == _this.loadMoreFailed)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as ContentSearchState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.refreshing,_this.loadingMore,_this.paused,_this.loadMoreFailed,_this.failure);
}

@override
String toString() {
  final _this = this as ContentSearchState;
  return 'ContentSearchState(items: ${_this.items}, nextCursor: ${_this.nextCursor}, refreshing: ${_this.refreshing}, loadingMore: ${_this.loadingMore}, paused: ${_this.paused}, loadMoreFailed: ${_this.loadMoreFailed}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $ContentSearchStateCopyWith<$Res>  {
  factory $ContentSearchStateCopyWith(ContentSearchState value, $Res Function(ContentSearchState) _then) = _$ContentSearchStateCopyWithImpl;
@useResult
$Res call({
 List<ContentSearchItem> items, String? nextCursor, bool refreshing, bool loadingMore, bool paused, bool loadMoreFailed, AppFailure? failure
});




}
/// @nodoc
class _$ContentSearchStateCopyWithImpl<$Res>
    implements $ContentSearchStateCopyWith<$Res> {
  _$ContentSearchStateCopyWithImpl(this._self, this._then);

  final ContentSearchState _self;
  final $Res Function(ContentSearchState) _then;

/// Create a copy of ContentSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? refreshing = null,Object? loadingMore = null,Object? paused = null,Object? loadMoreFailed = null,Object? failure = freezed,}) {
  return _then(ContentSearchState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ContentSearchItem>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentSearchState].
extension ContentSearchStatePatterns on ContentSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentSearchState value)  $default,){
final _that = this;
switch (_that) {
case _ContentSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _ContentSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ContentSearchItem> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentSearchState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ContentSearchItem> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _ContentSearchState():
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ContentSearchItem> items,  String? nextCursor,  bool refreshing,  bool loadingMore,  bool paused,  bool loadMoreFailed,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _ContentSearchState() when $default != null:
return $default(_that.items,_that.nextCursor,_that.refreshing,_that.loadingMore,_that.paused,_that.loadMoreFailed,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _ContentSearchState implements ContentSearchState {
  const _ContentSearchState({ List<ContentSearchItem> items = const <ContentSearchItem>[], this.nextCursor, this.refreshing = false, this.loadingMore = false, this.paused = false, this.loadMoreFailed = false, this.failure}): _items = items;
  

 final  List<ContentSearchItem> _items;
@override@JsonKey() List<ContentSearchItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override@JsonKey() final  bool refreshing;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  bool loadMoreFailed;
@override final  AppFailure? failure;

/// Create a copy of ContentSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentSearchStateCopyWith<_ContentSearchState> get copyWith => __$ContentSearchStateCopyWithImpl<_ContentSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentSearchState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,refreshing,loadingMore,paused,loadMoreFailed,failure);
}

@override
String toString() {
    return 'ContentSearchState(items: $items, nextCursor: $nextCursor, refreshing: $refreshing, loadingMore: $loadingMore, paused: $paused, loadMoreFailed: $loadMoreFailed, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ContentSearchStateCopyWith<$Res> implements $ContentSearchStateCopyWith<$Res> {
  factory _$ContentSearchStateCopyWith(_ContentSearchState value, $Res Function(_ContentSearchState) _then) = __$ContentSearchStateCopyWithImpl;
@override @useResult
$Res call({
 List<ContentSearchItem> items, String? nextCursor, bool refreshing, bool loadingMore, bool paused, bool loadMoreFailed, AppFailure? failure
});




}
/// @nodoc
class __$ContentSearchStateCopyWithImpl<$Res>
    implements _$ContentSearchStateCopyWith<$Res> {
  __$ContentSearchStateCopyWithImpl(this._self, this._then);

  final _ContentSearchState _self;
  final $Res Function(_ContentSearchState) _then;

/// Create a copy of ContentSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? refreshing = null,Object? loadingMore = null,Object? paused = null,Object? loadMoreFailed = null,Object? failure = freezed,}) {
  return _then(_ContentSearchState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ContentSearchItem>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
