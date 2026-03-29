// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greeting_line_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GreetingLineNotifier)
final greetingLineProvider = GreetingLineNotifierProvider._();

final class GreetingLineNotifierProvider
    extends $NotifierProvider<GreetingLineNotifier, String> {
  GreetingLineNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'greetingLineProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$greetingLineNotifierHash();

  @$internal
  @override
  GreetingLineNotifier create() => GreetingLineNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$greetingLineNotifierHash() =>
    r'ba1359f1c23a44ccfe6298bab707873a46d98289';

abstract class _$GreetingLineNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
