import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_pgc_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late Map<String, Object?> payload;
  setUp(() {
    dio = Dio();
    api = BilibiliApi(dio);
    payload = {
      'season_id': 281,
      'title': '作品',
      'evaluate': '简介',
      'episodes': <Object?>[
        {
          'id': 1,
          'cid': 2,
          'bvid': 'BVfixture',
          'title': '1',
          'long_title': '第一话',
          'status': 2,
          'cover': 'http://i0.hdslb.com/episode.jpg',
        },
      ],
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.resolve(
          Response<Object?>(
            requestOptions: request,
            statusCode: 200,
            data: {'code': 0, 'result': payload},
          ),
        ),
      ),
    );
  });
  tearDown(() {
    api.close();
    dio.close(force: true);
  });
  test(
    'public season facts and episode artwork map without inventing values',
    () async {
      payload.addAll({
        'styles': ['日常', '奇幻'],
        'stat': {
          'views': 79501303,
          'danmakus': 1653208,
          'follow_text': '348.2万系列追番',
        },
        'rating': {'score': 9.7, 'count': 34657},
        'publish': {'pub_time_show': '2014年10月06日'},
        'new_ep': {'desc': '已完结, 全14话'},
        'actors': '角色：配音',
        'staff': '导演：人员',
      });
      final season = (await BilibiliPgcRepository(
        api,
      ).season('281', CancellationSignal())).valueOrThrow;
      expect(season.facts.score, 9.7);
      expect(season.facts.ratingCount, 34657);
      expect(season.facts.views, 79501303);
      expect(season.facts.danmaku, 1653208);
      expect(season.facts.tags, ['日常', '奇幻']);
      expect(season.facts.followText, '348.2万系列追番');
      expect(season.facts.actors, '角色：配音');
      expect(season.facts.staff, '导演：人员');
      expect(
        season.episodes.single.coverUrl,
        'https://i0.hdslb.com/episode.jpg',
      );
    },
  );
  test(
    'missing metadata remains absent and malformed score is not displayed',
    () async {
      payload['rating'] = {'score': 99, 'count': -1};
      final season = (await BilibiliPgcRepository(
        api,
      ).season('281', CancellationSignal())).valueOrThrow;
      expect(season.facts.score, isNull);
      expect(season.facts.ratingCount, isNull);
      expect(season.facts.views, isNull);
      expect(season.facts.danmaku, isNull);
      expect(season.facts.tags, isEmpty);
    },
  );
}
