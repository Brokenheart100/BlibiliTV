// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bilibili_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiliVideoDto _$BiliVideoDtoFromJson(Map<String, dynamic> json) => BiliVideoDto(
  bvid: json['bvid'] as String,
  title: json['title'] as String,
  pic: coverUrl(json['pic'] as String),
  creator: readCreator(json, 'creator') as String,
  duration: durationSeconds(json['duration']),
  views: jsonInteger(readViews(json, 'views')),
  creatorAvatarUrl: avatarUrl(readCreatorAvatar(json, 'creatorAvatarUrl')),
);

BiliPartDto _$BiliPartDtoFromJson(Map<String, dynamic> json) => BiliPartDto(
  cid: jsonInteger(json['cid']),
  part: json['part'] as String,
  duration: durationSeconds(json['duration']),
);

DashTrackDto _$DashTrackDtoFromJson(Map<String, dynamic> json) => DashTrackDto(
  id: jsonInteger(json['id']),
  baseUrl: readBaseUrl(json, 'baseUrl') as String,
  codecs: json['codecs'] as String,
  bandwidth: jsonInteger(json['bandwidth']),
);
