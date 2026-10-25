// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryState {

 List<LibraryEntry> get items; String? get cursor; bool get loading; bool get mutating; AppFailure? get failure; String? get notice;
/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryStateCopyWith<LibraryState> get copyWith => _$LibraryStateCopyWithImpl<LibraryState>(this as LibraryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LibraryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.cursor, _this.cursor) || other.cursor == _this.cursor)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.mutating, _this.mutating) || other.mutating == _this.mutating)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.notice, _this.notice) || other.notice == _this.notice));
}


@override
int get hashCode {
  final _this = this as LibraryState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.cursor,_this.loading,_this.mutating,_this.failure,_this.notice);
}

@override
String toString() {
  final _this = this as LibraryState;
  return 'LibraryState(items: ${_this.items}, cursor: ${_this.cursor}, loading: ${_this.loading}, mutating: ${_this.mutating}, failure: ${_this.failure}, notice: ${_this.notice})';
}


}

/// @nodoc
abstract mixin class $LibraryStateCopyWith<$Res>  {
  factory $LibraryStateCopyWith(LibraryState value, $Res Function(LibraryState) _then) = _$LibraryStateCopyWithImpl;
@useResult
$Res call({
 List<LibraryEntry> items, String? cursor, bool loading, bool mutating, AppFailure? failure, String? notice
});




}
/// @nodoc
class _$LibraryStateCopyWithImpl<$Res>
    implements $LibraryStateCopyWith<$Res> {
  _$LibraryStateCopyWithImpl(this._self, this._then);

  final LibraryState _self;
  final $Res Function(LibraryState) _then;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? cursor = freezed,Object? loading = null,Object? mutating = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(LibraryState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LibraryEntry>,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,mutating: null == mutating ? _self.mutating : mutating // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryState].
extension LibraryStatePatterns on LibraryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryState value)  $default,){
final _that = this;
switch (_that) {
case _LibraryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryState value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LibraryEntry> items,  String? cursor,  bool loading,  bool mutating,  AppFailure? failure,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryState() when $default != null:
return $default(_that.items,_that.cursor,_that.loading,_that.mutating,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LibraryEntry> items,  String? cursor,  bool loading,  bool mutating,  AppFailure? failure,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _LibraryState():
return $default(_that.items,_that.cursor,_that.loading,_that.mutating,_that.failure,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LibraryEntry> items,  String? cursor,  bool loading,  bool mutating,  AppFailure? failure,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _LibraryState() when $default != null:
return $default(_that.items,_that.cursor,_that.loading,_that.mutating,_that.failure,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryState implements LibraryState {
  const _LibraryState({ List<LibraryEntry> items = const <LibraryEntry>[], this.cursor, this.loading = false, this.mutating = false, this.failure, this.notice}): _items = items;
  

 final  List<LibraryEntry> _items;
@override@JsonKey() List<LibraryEntry> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? cursor;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool mutating;
@override final  AppFailure? failure;
@override final  String? notice;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryStateCopyWith<_LibraryState> get copyWith => __$LibraryStateCopyWithImpl<_LibraryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.mutating, mutating) || other.mutating == mutating)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),cursor,loading,mutating,failure,notice);
}

@override
String toString() {
    return 'LibraryState(items: $items, cursor: $cursor, loading: $loading, mutating: $mutating, failure: $failure, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$LibraryStateCopyWith<$Res> implements $LibraryStateCopyWith<$Res> {
  factory _$LibraryStateCopyWith(_LibraryState value, $Res Function(_LibraryState) _then) = __$LibraryStateCopyWithImpl;
@override @useResult
$Res call({
 List<LibraryEntry> items, String? cursor, bool loading, bool mutating, AppFailure? failure, String? notice
});




}
/// @nodoc
class __$LibraryStateCopyWithImpl<$Res>
    implements _$LibraryStateCopyWith<$Res> {
  __$LibraryStateCopyWithImpl(this._self, this._then);

  final _LibraryState _self;
  final $Res Function(_LibraryState) _then;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? cursor = freezed,Object? loading = null,Object? mutating = null,Object? failure = freezed,Object? notice = freezed,}) {
  return _then(_LibraryState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LibraryEntry>,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,mutating: null == mutating ? _self.mutating : mutating // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PersonalActionsState {

 LibraryMembership? get membership; bool get busy; bool get pending; String? get pendingFolder; bool? get pendingDesired; String? get message;
/// Create a copy of PersonalActionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalActionsStateCopyWith<PersonalActionsState> get copyWith => _$PersonalActionsStateCopyWithImpl<PersonalActionsState>(this as PersonalActionsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PersonalActionsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalActionsState&&(identical(other.membership, _this.membership) || other.membership == _this.membership)&&(identical(other.busy, _this.busy) || other.busy == _this.busy)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&(identical(other.pendingFolder, _this.pendingFolder) || other.pendingFolder == _this.pendingFolder)&&(identical(other.pendingDesired, _this.pendingDesired) || other.pendingDesired == _this.pendingDesired)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as PersonalActionsState;
  return Object.hash(runtimeType,_this.membership,_this.busy,_this.pending,_this.pendingFolder,_this.pendingDesired,_this.message);
}

@override
String toString() {
  final _this = this as PersonalActionsState;
  return 'PersonalActionsState(membership: ${_this.membership}, busy: ${_this.busy}, pending: ${_this.pending}, pendingFolder: ${_this.pendingFolder}, pendingDesired: ${_this.pendingDesired}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $PersonalActionsStateCopyWith<$Res>  {
  factory $PersonalActionsStateCopyWith(PersonalActionsState value, $Res Function(PersonalActionsState) _then) = _$PersonalActionsStateCopyWithImpl;
@useResult
$Res call({
 LibraryMembership? membership, bool busy, bool pending, String? pendingFolder, bool? pendingDesired, String? message
});




}
/// @nodoc
class _$PersonalActionsStateCopyWithImpl<$Res>
    implements $PersonalActionsStateCopyWith<$Res> {
  _$PersonalActionsStateCopyWithImpl(this._self, this._then);

  final PersonalActionsState _self;
  final $Res Function(PersonalActionsState) _then;

/// Create a copy of PersonalActionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membership = freezed,Object? busy = null,Object? pending = null,Object? pendingFolder = freezed,Object? pendingDesired = freezed,Object? message = freezed,}) {
  return _then(PersonalActionsState(
membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as LibraryMembership?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,pendingFolder: freezed == pendingFolder ? _self.pendingFolder : pendingFolder // ignore: cast_nullable_to_non_nullable
as String?,pendingDesired: freezed == pendingDesired ? _self.pendingDesired : pendingDesired // ignore: cast_nullable_to_non_nullable
as bool?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalActionsState].
extension PersonalActionsStatePatterns on PersonalActionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalActionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalActionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalActionsState value)  $default,){
final _that = this;
switch (_that) {
case _PersonalActionsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalActionsState value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalActionsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LibraryMembership? membership,  bool busy,  bool pending,  String? pendingFolder,  bool? pendingDesired,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalActionsState() when $default != null:
return $default(_that.membership,_that.busy,_that.pending,_that.pendingFolder,_that.pendingDesired,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LibraryMembership? membership,  bool busy,  bool pending,  String? pendingFolder,  bool? pendingDesired,  String? message)  $default,) {final _that = this;
switch (_that) {
case _PersonalActionsState():
return $default(_that.membership,_that.busy,_that.pending,_that.pendingFolder,_that.pendingDesired,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LibraryMembership? membership,  bool busy,  bool pending,  String? pendingFolder,  bool? pendingDesired,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _PersonalActionsState() when $default != null:
return $default(_that.membership,_that.busy,_that.pending,_that.pendingFolder,_that.pendingDesired,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _PersonalActionsState implements PersonalActionsState {
  const _PersonalActionsState({this.membership, this.busy = false, this.pending = false, this.pendingFolder, this.pendingDesired, this.message});
  

@override final  LibraryMembership? membership;
@override@JsonKey() final  bool busy;
@override@JsonKey() final  bool pending;
@override final  String? pendingFolder;
@override final  bool? pendingDesired;
@override final  String? message;

/// Create a copy of PersonalActionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalActionsStateCopyWith<_PersonalActionsState> get copyWith => __$PersonalActionsStateCopyWithImpl<_PersonalActionsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalActionsState&&(identical(other.membership, membership) || other.membership == membership)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.pendingFolder, pendingFolder) || other.pendingFolder == pendingFolder)&&(identical(other.pendingDesired, pendingDesired) || other.pendingDesired == pendingDesired)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,membership,busy,pending,pendingFolder,pendingDesired,message);
}

@override
String toString() {
    return 'PersonalActionsState(membership: $membership, busy: $busy, pending: $pending, pendingFolder: $pendingFolder, pendingDesired: $pendingDesired, message: $message)';
}


}

/// @nodoc
abstract mixin class _$PersonalActionsStateCopyWith<$Res> implements $PersonalActionsStateCopyWith<$Res> {
  factory _$PersonalActionsStateCopyWith(_PersonalActionsState value, $Res Function(_PersonalActionsState) _then) = __$PersonalActionsStateCopyWithImpl;
@override @useResult
$Res call({
 LibraryMembership? membership, bool busy, bool pending, String? pendingFolder, bool? pendingDesired, String? message
});




}
/// @nodoc
class __$PersonalActionsStateCopyWithImpl<$Res>
    implements _$PersonalActionsStateCopyWith<$Res> {
  __$PersonalActionsStateCopyWithImpl(this._self, this._then);

  final _PersonalActionsState _self;
  final $Res Function(_PersonalActionsState) _then;

/// Create a copy of PersonalActionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membership = freezed,Object? busy = null,Object? pending = null,Object? pendingFolder = freezed,Object? pendingDesired = freezed,Object? message = freezed,}) {
  return _then(_PersonalActionsState(
membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as LibraryMembership?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,pendingFolder: freezed == pendingFolder ? _self.pendingFolder : pendingFolder // ignore: cast_nullable_to_non_nullable
as String?,pendingDesired: freezed == pendingDesired ? _self.pendingDesired : pendingDesired // ignore: cast_nullable_to_non_nullable
as bool?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
