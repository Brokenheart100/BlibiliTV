import 'package:json_annotation/json_annotation.dart';

part 'bilibili_dto.g.dart';

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected object');
  }
  return value;
}

List<Object?> jsonList(Object? value) {
  if (value is! List<Object?>) throw const FormatException('Expected list');
  return value;
}

int jsonInteger(Object? value) => switch (value) {
  num() => value.toInt(),
  String() => int.parse(value),
  _ => throw const FormatException('Expected integer'),
};
int durationSeconds(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) {
    final fields = value.split(':');
    if (fields.length > 3) throw const FormatException('Invalid duration');
    return fields.fold(0, (total, item) => total * 60 + int.parse(item.trim()));
  }
  throw const FormatException('Expected duration');
}

String coverUrl(String value) {
  if (value.isEmpty) return value;
  final uri = Uri.parse(value.startsWith('//') ? 'https:$value' : value);
  return uri.scheme == 'http'
      ? uri.replace(scheme: 'https').toString()
      : uri.toString();
}

Object? readCreator(Map<dynamic, dynamic> json, String _) =>
    json['owner'] is Map<Object?, Object?>
    ? (json['owner']! as Map<Object?, Object?>)['name']
    : json['author'];
String? avatarUrl(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final uri = Uri.tryParse(value.startsWith('//') ? 'https:$value' : value);
  if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  return switch (uri.scheme) {
    'https' => uri.toString(),
    'http' => uri.replace(scheme: 'https').toString(),
    _ => null,
  };
}

Object? readCreatorAvatar(Map<dynamic, dynamic> json, String _) =>
    json['owner'] is Map<Object?, Object?>
    ? (json['owner']! as Map<Object?, Object?>)['face']
    : json['upic'];
Object? readViews(Map<dynamic, dynamic> json, String _) =>
    json['stat'] is Map<Object?, Object?>
    ? (json['stat']! as Map<Object?, Object?>)['view']
    : json['play'];
Object? readBaseUrl(Map<dynamic, dynamic> json, String _) =>
    json['baseUrl'] ?? json['base_url'];

@JsonSerializable(createToJson: false)
class BiliVideoDto {
  const BiliVideoDto({
    required this.bvid,
    required this.title,
    required this.pic,
    required this.creator,
    required this.duration,
    required this.views,
    this.creatorAvatarUrl,
  });
  factory BiliVideoDto.fromJson(Map<String, Object?> json) =>
      _$BiliVideoDtoFromJson(json);
  final String bvid, title;
  @JsonKey(fromJson: coverUrl)
  final String pic;
  @JsonKey(readValue: readCreator)
  final String creator;
  @JsonKey(readValue: readCreatorAvatar, fromJson: avatarUrl)
  final String? creatorAvatarUrl;
  @JsonKey(fromJson: durationSeconds)
  final int duration;
  @JsonKey(readValue: readViews, fromJson: jsonInteger)
  final int views;
}

@JsonSerializable(createToJson: false)
class BiliPartDto {
  const BiliPartDto({
    required this.cid,
    required this.part,
    required this.duration,
  });
  factory BiliPartDto.fromJson(Map<String, Object?> json) =>
      _$BiliPartDtoFromJson(json);
  @JsonKey(fromJson: jsonInteger)
  final int cid;
  final String part;
  @JsonKey(fromJson: durationSeconds)
  final int duration;
}

@JsonSerializable(createToJson: false)
class DashTrackDto {
  const DashTrackDto({
    required this.id,
    required this.baseUrl,
    required this.codecs,
    required this.bandwidth,
  });
  factory DashTrackDto.fromJson(Map<String, Object?> json) =>
      _$DashTrackDtoFromJson(json);
  @JsonKey(fromJson: jsonInteger)
  final int id;
  @JsonKey(readValue: readBaseUrl)
  final String baseUrl;
  final String codecs;
  @JsonKey(fromJson: jsonInteger)
  final int bandwidth;
}
