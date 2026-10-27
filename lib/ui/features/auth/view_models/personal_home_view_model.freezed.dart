// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_home_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PersonalCollectionState {

 List<PersonalItem> get items; String? get cursor; bool get loading; AppFailure? get failure; String? get notice;
/// Create a copy of PersonalCollectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalCollectionStateCopyWith<PersonalCollectionState> get copyWith => _$PersonalCollectionStateCopyWithImpl<PersonalCollectionState>(this as PersonalCollectionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PersonalCollectionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalCollectionState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.cursor, _this.cursor) || other.cursor == _this.cursor)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as PersonalCollectionState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.cursor,_this.loading,_this.failure,_this.notice);
}

@override
String toString() {
  final _this = this as PersonalCollectionState;
  return 'PersonalCollectionState(items: ${_this.items}, cursor: ${_this.cursor}, loading: ${_this.loading}, failure: ${_this.failure}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $PersonalCollectionStateCopyWith<$Res>  {
  factory $PersonalCollectionStateCopyWith(PersonalCollectionState value, $Res Function(PersonalCollectionState) _then) = _$PersonalCollectionStateCopyWithImpl;
@useResult
$Res call({
 List<PersonalItem> items, String? cursor, bool loading, AppFailure? failure, String? notice
});




}
/// @nodoc
class _$PersonalCollectionStateCopyWithImpl<$Res>
    implements $PersonalCollectionStateCopyWith<$Res> {
  _$PersonalCollectionStateCopyWithImpl(this._self, this._then);

  final PersonalCollectionState _self;
  final $Res Function(PersonalCollectionState) _then;

/// Create a copy of PersonalCollectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? cursor = freezed,Object? loading = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(PersonalCollectionState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PersonalItem>,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalCollectionState].
extension PersonalCollectionStatePatterns on PersonalCollectionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalCollectionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalCollectionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalCollectionState value)  $default,){
final _that = this;
switch (_that) {
case _PersonalCollectionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalCollectionState value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalCollectionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PersonalItem> items,  String? cursor,  bool loading,  AppFailure? failure,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalCollectionState() when $default != null:
return $default(_that.items,_that.cursor,_that.loading,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PersonalItem> items,  String? cursor,  bool loading,  AppFailure? failure,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _PersonalCollectionState():
return $default(_that.items,_that.cursor,_that.loading,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PersonalItem> items,  String? cursor,  bool loading,  AppFailure? failure,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _PersonalCollectionState() when $default != null:
return $default(_that.items,_that.cursor,_that.loading,_that.failure,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _PersonalCollectionState implements PersonalCollectionState {
  const _PersonalCollectionState({ List<PersonalItem> items = const <PersonalItem>[], this.cursor, this.loading = false, this.failure, this.notice}): _items = items;
  

 final  List<PersonalItem> _items;
@override@JsonKey() List<PersonalItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? cursor;
@override@JsonKey() final  bool loading;
@override final  AppFailure? failure;
@override final  String? notice;

/// Create a copy of PersonalCollectionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalCollectionStateCopyWith<_PersonalCollectionState> get copyWith => __$PersonalCollectionStateCopyWithImpl<_PersonalCollectionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalCollectionState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),cursor,loading,failure,notice);
}

@override
String toString() {
    return 'PersonalCollectionState(items: $items, cursor: $cursor, loading: $loading, failure: $failure, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$PersonalCollectionStateCopyWith<$Res> implements $PersonalCollectionStateCopyWith<$Res> {
  factory _$PersonalCollectionStateCopyWith(_PersonalCollectionState value, $Res Function(_PersonalCollectionState) _then) = __$PersonalCollectionStateCopyWithImpl;
@override @useResult
$Res call({
 List<PersonalItem> items, String? cursor, bool loading, AppFailure? failure, String? notice
});




}
/// @nodoc
class __$PersonalCollectionStateCopyWithImpl<$Res>
    implements _$PersonalCollectionStateCopyWith<$Res> {
  __$PersonalCollectionStateCopyWithImpl(this._self, this._then);

  final _PersonalCollectionState _self;
  final $Res Function(_PersonalCollectionState) _then;

/// Create a copy of PersonalCollectionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? cursor = freezed,Object? loading = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(_PersonalCollectionState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PersonalItem>,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
