import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Protocol implementation; provenance and upstream commit are in api-contracts.
Map<String, Object> signWbi(
  Map<String, Object> parameters,
  String imageKey,
  String subKey, {
  required int timestamp,
}) {
  const permutation = <int>[
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
  ];
  final combined = imageKey + subKey;
  if (combined.length < 64) throw const FormatException('Invalid WBI key');
  final mixin = permutation.map((index) => combined[index]).join();
  final filter = RegExp(r"[!'()*]");
  final result = <String, Object>{
    for (final entry in parameters.entries)
      entry.key: entry.value.toString().replaceAll(filter, ''),
    'wts': timestamp,
  };
  final keys = result.keys.toList()..sort();
  final query = keys
      .map(
        (key) =>
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(result[key].toString())}',
      )
      .join('&');
  result['w_rid'] = md5.convert(utf8.encode(query + mixin)).toString();
  return result;
}
