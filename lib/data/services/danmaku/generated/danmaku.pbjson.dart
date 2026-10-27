// This is a generated file - do not edit.
//
// Generated from danmaku.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use segmentConfigDescriptor instead')
const SegmentConfig$json = {
  '1': 'SegmentConfig',
  '2': [
    {'1': 'page_size', '3': 1, '4': 1, '5': 3, '10': 'pageSize'},
    {'1': 'total', '3': 2, '4': 1, '5': 3, '10': 'total'},
  ],
};

/// Descriptor for `SegmentConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List segmentConfigDescriptor = $convert.base64Decode(
    'Cg1TZWdtZW50Q29uZmlnEhsKCXBhZ2Vfc2l6ZRgBIAEoA1IIcGFnZVNpemUSFAoFdG90YWwYAi'
    'ABKANSBXRvdGFs');

@$core.Deprecated('Use webViewDescriptor instead')
const WebView$json = {
  '1': 'WebView',
  '2': [
    {
      '1': 'dm_sge',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.mambatv.web.SegmentConfig',
      '10': 'dmSge'
    },
  ],
};

/// Descriptor for `WebView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webViewDescriptor = $convert.base64Decode(
    'CgdXZWJWaWV3EjEKBmRtX3NnZRgEIAEoCzIaLm1hbWJhdHYud2ViLlNlZ21lbnRDb25maWdSBW'
    'RtU2dl');

@$core.Deprecated('Use danmakuEntryDescriptor instead')
const DanmakuEntry$json = {
  '1': 'DanmakuEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'progress', '3': 2, '4': 1, '5': 5, '10': 'progress'},
    {'1': 'mode', '3': 3, '4': 1, '5': 5, '10': 'mode'},
    {'1': 'fontsize', '3': 4, '4': 1, '5': 5, '10': 'fontsize'},
    {'1': 'color', '3': 5, '4': 1, '5': 13, '10': 'color'},
    {'1': 'content', '3': 7, '4': 1, '5': 9, '10': 'content'},
    {'1': 'id_str', '3': 12, '4': 1, '5': 9, '10': 'idStr'},
  ],
};

/// Descriptor for `DanmakuEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List danmakuEntryDescriptor = $convert.base64Decode(
    'CgxEYW5tYWt1RW50cnkSDgoCaWQYASABKANSAmlkEhoKCHByb2dyZXNzGAIgASgFUghwcm9ncm'
    'VzcxISCgRtb2RlGAMgASgFUgRtb2RlEhoKCGZvbnRzaXplGAQgASgFUghmb250c2l6ZRIUCgVj'
    'b2xvchgFIAEoDVIFY29sb3ISGAoHY29udGVudBgHIAEoCVIHY29udGVudBIVCgZpZF9zdHIYDC'
    'ABKAlSBWlkU3Ry');

@$core.Deprecated('Use segmentDescriptor instead')
const Segment$json = {
  '1': 'Segment',
  '2': [
    {
      '1': 'elems',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.mambatv.web.DanmakuEntry',
      '10': 'elems'
    },
  ],
};

/// Descriptor for `Segment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List segmentDescriptor = $convert.base64Decode(
    'CgdTZWdtZW50Ei8KBWVsZW1zGAEgAygLMhkubWFtYmF0di53ZWIuRGFubWFrdUVudHJ5UgVlbG'
    'Vtcw==');
