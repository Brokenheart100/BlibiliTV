import 'dart:async';

import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/personal_home.dart';

class FakePersonalHomeRepository implements PersonalHomeRepository {
  FakePersonalHomeRepository({this.session});
  final Session Function()? session;
  PersonalProfile? profileValue;
  final calls = <(String, PersonalSection, String?)>[];
  final signals = <CancellationSignal>[];
  final pages = <String, PageSlice<PersonalItem>>{};
  Completer<Result<PageSlice<PersonalItem>>>? gate;
  AppFailure? failure;
  @override
  Future<Result<PersonalProfile>> profile(
    String ownerKey,
    CancellationSignal cancellation,
  ) async => Success(
    profileValue ??
        PersonalProfile(
          mid: int.tryParse(ownerKey.replaceFirst('user:', '')) ?? 1,
          name: session?.call().displayName ?? '合成验收账号',
        ),
  );
  @override
  Future<Result<PageSlice<PersonalItem>>> list({
    required String ownerKey,
    required PersonalSection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    calls.add((ownerKey, section, cursor));
    signals.add(cancellation);
    if (gate != null) return gate!.future;
    if (failure != null) return ResultFailure(failure!);
    return Success(
      pages['$ownerKey:${section.name}:${cursor ?? "first"}'] ??
          pages[section.name] ??
          PageSlice(items: const []),
    );
  }
}
