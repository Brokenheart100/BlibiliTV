// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentBrowseState {

 List<VideoSummary> get items; int? get nextPage; bool get loadingMore; AppFailure? get failure;
/// Create a copy of ContentBrowseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentBrowseStateCopyWith<ContentBrowseState> get copyWith => _$ContentBrowseStateCopyWithImpl<ContentBrowseState>(this as ContentBrowseState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContentBrowseState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentBrowseState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextPage, _this.nextPage) || other.nextPage == _this.nextPage)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as ContentBrowseState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextPage,_this.loadingMore,_this.failure);
}

@override
String toString() {
  final _this = this as ContentBrowseState;
  return 'ContentBrowseState(items: ${_this.items}, nextPage: ${_this.nextPage}, loadingMore: ${_this.loadingMore}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $ContentBrowseStateCopyWith<$Res>  {
  factory $ContentBrowseStateCopyWith(ContentBrowseState value, $Res Function(ContentBrowseState) _then) = _$ContentBrowseStateCopyWithImpl;
@useResult
$Res call({
 List<VideoSummary> items, int? nextPage, bool loadingMore, AppFailure? failure
});




}
/// @nodoc
class _$ContentBrowseStateCopyWithImpl<$Res>
    implements $ContentBrowseStateCopyWith<$Res> {
  _$ContentBrowseStateCopyWithImpl(this._self, this._then);

  final ContentBrowseState _self;
  final $Res Function(ContentBrowseState) _then;

/// Create a copy of ContentBrowseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextPage = freezed,Object? loadingMore = null,Object? failure = freezed,}) {
  return _then(ContentBrowseState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<VideoSummary>,nextPage: freezed == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentBrowseState].
extension ContentBrowseStatePatterns on ContentBrowseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentBrowseState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentBrowseState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentBrowseState value)  $default,){
final _that = this;
switch (_that) {
case _ContentBrowseState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentBrowseState value)?  $default,){
final _that = this;
switch (_that) {
case _ContentBrowseState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<VideoSummary> items,  int? nextPage,  bool loadingMore,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentBrowseState() when $default != null:
return $default(_that.items,_that.nextPage,_that.loadingMore,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<VideoSummary> items,  int? nextPage,  bool loadingMore,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _ContentBrowseState():
return $default(_that.items,_that.nextPage,_that.loadingMore,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<VideoSummary> items,  int? nextPage,  bool loadingMore,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _ContentBrowseState() when $default != null:
return $default(_that.items,_that.nextPage,_that.loadingMore,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _ContentBrowseState implements ContentBrowseState {
  const _ContentBrowseState({ List<VideoSummary> items = const <VideoSummary>[], this.nextPage, this.loadingMore = false, this.failure}): _items = items;
  

 final  List<VideoSummary> _items;
@override@JsonKey() List<VideoSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int? nextPage;
@override@JsonKey() final  bool loadingMore;
@override final  AppFailure? failure;

/// Create a copy of ContentBrowseState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentBrowseStateCopyWith<_ContentBrowseState> get copyWith => __$ContentBrowseStateCopyWithImpl<_ContentBrowseState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentBrowseState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextPage, nextPage) || other.nextPage == nextPage)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextPage,loadingMore,failure);
}

@override
String toString() {
    return 'ContentBrowseState(items: $items, nextPage: $nextPage, loadingMore: $loadingMore, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ContentBrowseStateCopyWith<$Res> implements $ContentBrowseStateCopyWith<$Res> {
  factory _$ContentBrowseStateCopyWith(_ContentBrowseState value, $Res Function(_ContentBrowseState) _then) = __$ContentBrowseStateCopyWithImpl;
@override @useResult
$Res call({
 List<VideoSummary> items, int? nextPage, bool loadingMore, AppFailure? failure
});




}
/// @nodoc
class __$ContentBrowseStateCopyWithImpl<$Res>
    implements _$ContentBrowseStateCopyWith<$Res> {
  __$ContentBrowseStateCopyWithImpl(this._self, this._then);

  final _ContentBrowseState _self;
  final $Res Function(_ContentBrowseState) _then;

/// Create a copy of ContentBrowseState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextPage = freezed,Object? loadingMore = null,Object? failure = freezed,}) {
  return _then(_ContentBrowseState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VideoSummary>,nextPage: freezed == nextPage ? _self.nextPage : nextPage // ignore: cast_nullable_to_non_nullable
as int?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
