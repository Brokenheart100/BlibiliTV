// This is a generated file - do not edit.
//
// Generated from danmaku.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SegmentConfig extends $pb.GeneratedMessage {
  factory SegmentConfig({
    $fixnum.Int64? pageSize,
    $fixnum.Int64? total,
  }) {
    final result = create();
    if (pageSize != null) result.pageSize = pageSize;
    if (total != null) result.total = total;
    return result;
  }

  SegmentConfig._();

  factory SegmentConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SegmentConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SegmentConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'mambatv.web'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'pageSize')
    ..aInt64(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SegmentConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SegmentConfig copyWith(void Function(SegmentConfig) updates) =>
      super.copyWith((message) => updates(message as SegmentConfig))
          as SegmentConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SegmentConfig create() => SegmentConfig._();
  @$core.override
  SegmentConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SegmentConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SegmentConfig>(create);
  static SegmentConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get pageSize => $_getI64(0);
  @$pb.TagNumber(1)
  set pageSize($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageSize() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get total => $_getI64(1);
  @$pb.TagNumber(2)
  set total($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class WebView extends $pb.GeneratedMessage {
  factory WebView({
    SegmentConfig? dmSge,
  }) {
    final result = create();
    if (dmSge != null) result.dmSge = dmSge;
    return result;
  }

  WebView._();

  factory WebView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebView',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'mambatv.web'),
      createEmptyInstance: create)
    ..aOM<SegmentConfig>(4, _omitFieldNames ? '' : 'dmSge',
        subBuilder: SegmentConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebView clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebView copyWith(void Function(WebView) updates) =>
      super.copyWith((message) => updates(message as WebView)) as WebView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebView create() => WebView._();
  @$core.override
  WebView createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebView getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WebView>(create);
  static WebView? _defaultInstance;

  @$pb.TagNumber(4)
  SegmentConfig get dmSge => $_getN(0);
  @$pb.TagNumber(4)
  set dmSge(SegmentConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDmSge() => $_has(0);
  @$pb.TagNumber(4)
  void clearDmSge() => $_clearField(4);
  @$pb.TagNumber(4)
  SegmentConfig ensureDmSge() => $_ensure(0);
}

class DanmakuEntry extends $pb.GeneratedMessage {
  factory DanmakuEntry({
    $fixnum.Int64? id,
    $core.int? progress,
    $core.int? mode,
    $core.int? fontsize,
    $core.int? color,
    $core.String? content,
    $core.String? idStr,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (progress != null) result.progress = progress;
    if (mode != null) result.mode = mode;
    if (fontsize != null) result.fontsize = fontsize;
    if (color != null) result.color = color;
    if (content != null) result.content = content;
    if (idStr != null) result.idStr = idStr;
    return result;
  }

  DanmakuEntry._();

  factory DanmakuEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DanmakuEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DanmakuEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'mambatv.web'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'progress')
    ..aI(3, _omitFieldNames ? '' : 'mode')
    ..aI(4, _omitFieldNames ? '' : 'fontsize')
    ..aI(5, _omitFieldNames ? '' : 'color', fieldType: $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'content')
    ..aOS(12, _omitFieldNames ? '' : 'idStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DanmakuEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DanmakuEntry copyWith(void Function(DanmakuEntry) updates) =>
      super.copyWith((message) => updates(message as DanmakuEntry))
          as DanmakuEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DanmakuEntry create() => DanmakuEntry._();
  @$core.override
  DanmakuEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DanmakuEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DanmakuEntry>(create);
  static DanmakuEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get progress => $_getIZ(1);
  @$pb.TagNumber(2)
  set progress($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProgress() => $_has(1);
  @$pb.TagNumber(2)
  void clearProgress() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get mode => $_getIZ(2);
  @$pb.TagNumber(3)
  set mode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get fontsize => $_getIZ(3);
  @$pb.TagNumber(4)
  set fontsize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFontsize() => $_has(3);
  @$pb.TagNumber(4)
  void clearFontsize() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get color => $_getIZ(4);
  @$pb.TagNumber(5)
  set color($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasColor() => $_has(4);
  @$pb.TagNumber(5)
  void clearColor() => $_clearField(5);

  @$pb.TagNumber(7)
  $core.String get content => $_getSZ(5);
  @$pb.TagNumber(7)
  set content($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasContent() => $_has(5);
  @$pb.TagNumber(7)
  void clearContent() => $_clearField(7);

  @$pb.TagNumber(12)
  $core.String get idStr => $_getSZ(6);
  @$pb.TagNumber(12)
  set idStr($core.String value) => $_setString(6, value);
  @$pb.TagNumber(12)
  $core.bool hasIdStr() => $_has(6);
  @$pb.TagNumber(12)
  void clearIdStr() => $_clearField(12);
}

class Segment extends $pb.GeneratedMessage {
  factory Segment({
    $core.Iterable<DanmakuEntry>? elems,
  }) {
    final result = create();
    if (elems != null) result.elems.addAll(elems);
    return result;
  }

  Segment._();

  factory Segment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Segment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Segment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'mambatv.web'),
      createEmptyInstance: create)
    ..pPM<DanmakuEntry>(1, _omitFieldNames ? '' : 'elems',
        subBuilder: DanmakuEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment copyWith(void Function(Segment) updates) =>
      super.copyWith((message) => updates(message as Segment)) as Segment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Segment create() => Segment._();
  @$core.override
  Segment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Segment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Segment>(create);
  static Segment? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DanmakuEntry> get elems => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
