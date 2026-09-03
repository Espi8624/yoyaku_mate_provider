// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waiting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$waitingServiceHash() => r'0aa87ad56050c69a0b98091a18a3bde2f63b587e';

/// See also [waitingService].
@ProviderFor(waitingService)
final waitingServiceProvider = AutoDisposeProvider<WaitingService>.internal(
  waitingService,
  name: r'waitingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$waitingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WaitingServiceRef = AutoDisposeProviderRef<WaitingService>;
String _$waitingListNotifierHash() =>
    r'4f1d0eeccbb7ab227c4ecd1d195c1ee8c22b02ab';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$WaitingListNotifier
    extends BuildlessAutoDisposeAsyncNotifier<WaitingListData> {
  late final String storeId;

  FutureOr<WaitingListData> build({
    required String storeId,
  });
}

/// See also [WaitingListNotifier].
@ProviderFor(WaitingListNotifier)
const waitingListNotifierProvider = WaitingListNotifierFamily();

/// See also [WaitingListNotifier].
class WaitingListNotifierFamily extends Family<AsyncValue<WaitingListData>> {
  /// See also [WaitingListNotifier].
  const WaitingListNotifierFamily();

  /// See also [WaitingListNotifier].
  WaitingListNotifierProvider call({
    required String storeId,
  }) {
    return WaitingListNotifierProvider(
      storeId: storeId,
    );
  }

  @override
  WaitingListNotifierProvider getProviderOverride(
    covariant WaitingListNotifierProvider provider,
  ) {
    return call(
      storeId: provider.storeId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'waitingListNotifierProvider';
}

/// See also [WaitingListNotifier].
class WaitingListNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    WaitingListNotifier, WaitingListData> {
  /// See also [WaitingListNotifier].
  WaitingListNotifierProvider({
    required String storeId,
  }) : this._internal(
          () => WaitingListNotifier()..storeId = storeId,
          from: waitingListNotifierProvider,
          name: r'waitingListNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$waitingListNotifierHash,
          dependencies: WaitingListNotifierFamily._dependencies,
          allTransitiveDependencies:
              WaitingListNotifierFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  WaitingListNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storeId,
  }) : super.internal();

  final String storeId;

  @override
  FutureOr<WaitingListData> runNotifierBuild(
    covariant WaitingListNotifier notifier,
  ) {
    return notifier.build(
      storeId: storeId,
    );
  }

  @override
  Override overrideWith(WaitingListNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WaitingListNotifierProvider._internal(
        () => create()..storeId = storeId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storeId: storeId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<WaitingListNotifier, WaitingListData>
      createElement() {
    return _WaitingListNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WaitingListNotifierProvider && other.storeId == storeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WaitingListNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<WaitingListData> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _WaitingListNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<WaitingListNotifier,
        WaitingListData> with WaitingListNotifierRef {
  _WaitingListNotifierProviderElement(super.provider);

  @override
  String get storeId => (origin as WaitingListNotifierProvider).storeId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
