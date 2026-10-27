import 'package:xml/xml.dart';

import '../../../core/result.dart';
import '../../../domain/playback/playback.dart';

/// Builds an in-memory MPD for one selected video/audio pair. Never log it.
String buildDashManifest(PlaybackSource source) {
  final video = source.videoDash, audio = source.audioDash;
  if (video == null || audio == null || source.duration <= Duration.zero) {
    throw const AppFailure(FailureKind.unsupported, '此视频缺少 DASH 播放信息');
  }
  final builder = XmlBuilder();
  final duration = 'PT${source.duration.inMicroseconds / 1000000}S';
  void representation(DashRepresentation track, String url, String type) {
    for (final range in [track.initializationRange, track.indexRange]) {
      final match = RegExp(r'^(\d+)-(\d+)$').firstMatch(range);
      if (match == null || int.parse(match[1]!) > int.parse(match[2]!)) {
        throw const AppFailure(FailureKind.contract, 'DASH 分段信息无效');
      }
    }
    if (track.bandwidth <= 0 || Uri.tryParse(url)?.scheme != 'https') {
      throw const AppFailure(FailureKind.contract, 'DASH 资源信息无效');
    }
    builder.element(
      'AdaptationSet',
      attributes: {'contentType': type, 'mimeType': track.mimeType},
      nest: () {
        builder.element(
          'Representation',
          attributes: {
            'id': type,
            'bandwidth': '${track.bandwidth}',
            'codecs': track.codecs,
            if (track.width > 0) 'width': '${track.width}',
            if (track.height > 0) 'height': '${track.height}',
            if (track.audioSamplingRate > 0)
              'audioSamplingRate': '${track.audioSamplingRate}',
          },
          nest: () {
            builder.element('BaseURL', nest: () => builder.text(url));
            builder.element(
              'SegmentBase',
              attributes: {'indexRange': track.indexRange},
              nest: () {
                builder.element(
                  'Initialization',
                  attributes: {'range': track.initializationRange},
                );
              },
            );
          },
        );
      },
    );
  }

  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element(
    'MPD',
    attributes: {
      'xmlns': 'urn:mpeg:dash:schema:mpd:2011',
      'type': 'static',
      'profiles': 'urn:mpeg:dash:profile:isoff-on-demand:2011',
      'mediaPresentationDuration': duration,
      'minBufferTime': 'PT1.5S',
    },
    nest: () {
      builder.element(
        'Period',
        attributes: {'start': 'PT0S', 'duration': duration},
        nest: () {
          representation(video, source.videoUrl, 'video');
          representation(audio, source.audioUrl, 'audio');
        },
      );
    },
  );
  return builder.buildDocument().toXmlString();
}
