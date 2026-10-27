import 'package:mambatv/domain/playback/playback.dart';

const dashSource = PlaybackSource(
  videoUrl: 'https://cdn.invalid/video?token=synthetic&x=1',
  audioUrl: 'https://cdn.invalid/audio?token=synthetic&x=2',
  duration: Duration(seconds: 120),
  quality: 32,
  codec: 'avc1.64001F',
  videoBackups: ['https://backup.invalid/video'],
  audioBackups: ['https://backup.invalid/audio'],
  videoDash: DashRepresentation(
    codecs: 'avc1.64001F',
    mimeType: 'video/mp4',
    bandwidth: 300000,
    initializationRange: '0-999',
    indexRange: '1000-1999',
    width: 640,
    height: 360,
  ),
  audioDash: DashRepresentation(
    codecs: 'mp4a.40.2',
    mimeType: 'audio/mp4',
    bandwidth: 128000,
    initializationRange: '0-699',
    indexRange: '700-999',
    audioSamplingRate: 44100,
  ),
);
