// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_login_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QrLoginViewModel)
final qrLoginViewModelProvider = QrLoginViewModelFamily._();

final class QrLoginViewModelProvider
    extends $NotifierProvider<QrLoginViewModel, QrLoginState> {
  QrLoginViewModelProvider._({
    required QrLoginViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'qrLoginViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$qrLoginViewModelHash();

  @override
  String toString() {
    return r'qrLoginViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QrLoginViewModel create() => QrLoginViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrLoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrLoginState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QrLoginViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$qrLoginViewModelHash() => r'1ab1e6154f1c9bf6377844ee67f77ce5dcdf154a';

final class QrLoginViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          QrLoginViewModel,
          QrLoginState,
          QrLoginState,
          QrLoginState,
          String
        > {
  QrLoginViewModelFamily._()
    : super(
        retry: null,
        name: r'qrLoginViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QrLoginViewModelProvider call({required String pageId}) =>
      QrLoginViewModelProvider._(argument: pageId, from: this);

  @override
  String toString() => r'qrLoginViewModelProvider';
}

abstract class _$QrLoginViewModel extends $Notifier<QrLoginState> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  QrLoginState build({required String pageId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QrLoginState, QrLoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QrLoginState, QrLoginState>,
              QrLoginState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(pageId: _$args));
  }
}
