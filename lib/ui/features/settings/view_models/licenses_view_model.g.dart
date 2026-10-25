// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'licenses_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(licenseNotices)
final licenseNoticesProvider = LicenseNoticesProvider._();

final class LicenseNoticesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LicenseNotice>>,
          List<LicenseNotice>,
          FutureOr<List<LicenseNotice>>
        >
    with
        $FutureModifier<List<LicenseNotice>>,
        $FutureProvider<List<LicenseNotice>> {
  LicenseNoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'licenseNoticesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$licenseNoticesHash();

  @$internal
  @override
  $FutureProviderElement<List<LicenseNotice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LicenseNotice>> create(Ref ref) {
    return licenseNotices(ref);
  }
}

String _$licenseNoticesHash() => r'7e1672c2e2e47a3556468f113b1c3be776463e7a';
