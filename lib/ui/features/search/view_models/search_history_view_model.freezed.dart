// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_history_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchHistoryState {

 List<String> get items; AppFailure? get failure;
/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchHistoryStateCopyWith<SearchHistoryState> get copyWith => _$SearchHistoryStateCopyWithImpl<SearchHistoryState>(this as SearchHistoryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchHistoryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchHistoryState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as SearchHistoryState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.failure);
}

@override
String toString() {
  final _this = this as SearchHistoryState;
  return 'SearchHistoryState(items: ${_this.items}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $SearchHistoryStateCopyWith<$Res>  {
  factory $SearchHistoryStateCopyWith(SearchHistoryState value, $Res Function(SearchHistoryState) _then) = _$SearchHistoryStateCopyWithImpl;
@useResult
$Res call({
 List<String> items, AppFailure? failure
});




}
/// @nodoc
class _$SearchHistoryStateCopyWithImpl<$Res>
    implements $SearchHistoryStateCopyWith<$Res> {
  _$SearchHistoryStateCopyWithImpl(this._self, this._then);

  final SearchHistoryState _self;
  final $Res Function(SearchHistoryState) _then;

/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? failure = freezed,}) {
  return _then(SearchHistoryState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<String>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchHistoryState].
extension SearchHistoryStatePatterns on SearchHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _SearchHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> items,  AppFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
return $default(_that.items,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> items,  AppFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _SearchHistoryState():
return $default(_that.items,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> items,  AppFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _SearchHistoryState() when $default != null:
return $default(_that.items,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _SearchHistoryState implements SearchHistoryState {
  const _SearchHistoryState({ List<String> items = const <String>[], this.failure}): _items = items;
  

 final  List<String> _items;
@override@JsonKey() List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  AppFailure? failure;

/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchHistoryStateCopyWith<_SearchHistoryState> get copyWith => __$SearchHistoryStateCopyWithImpl<_SearchHistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchHistoryState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),failure);
}

@override
String toString() {
    return 'SearchHistoryState(items: $items, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$SearchHistoryStateCopyWith<$Res> implements $SearchHistoryStateCopyWith<$Res> {
  factory _$SearchHistoryStateCopyWith(_SearchHistoryState value, $Res Function(_SearchHistoryState) _then) = __$SearchHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> items, AppFailure? failure
});




}
/// @nodoc
class __$SearchHistoryStateCopyWithImpl<$Res>
    implements _$SearchHistoryStateCopyWith<$Res> {
  __$SearchHistoryStateCopyWithImpl(this._self, this._then);

  final _SearchHistoryState _self;
  final $Res Function(_SearchHistoryState) _then;

/// Create a copy of SearchHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? failure = freezed,}) {
  return _then(_SearchHistoryState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
