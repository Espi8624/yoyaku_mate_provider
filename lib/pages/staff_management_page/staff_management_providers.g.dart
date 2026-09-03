// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_management_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffListHash() => r'967de3dfde65ad4ab2895a4895d3aaa2ed4d79d8';

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

/// See also [staffList].
@ProviderFor(staffList)
const staffListProvider = StaffListFamily();

/// See also [staffList].
class StaffListFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [staffList].
  const StaffListFamily();

  /// See also [staffList].
  StaffListProvider call({
    required String storeId,
  }) {
    return StaffListProvider(
      storeId: storeId,
    );
  }

  @override
  StaffListProvider getProviderOverride(
    covariant StaffListProvider provider,
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
  String? get name => r'staffListProvider';
}

/// See also [staffList].
class StaffListProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [staffList].
  StaffListProvider({
    required String storeId,
  }) : this._internal(
          (ref) => staffList(
            ref as StaffListRef,
            storeId: storeId,
          ),
          from: staffListProvider,
          name: r'staffListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$staffListHash,
          dependencies: StaffListFamily._dependencies,
          allTransitiveDependencies: StaffListFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  StaffListProvider._internal(
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
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(StaffListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StaffListProvider._internal(
        (ref) => create(ref as StaffListRef),
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
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _StaffListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffListProvider && other.storeId == storeId;
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
mixin StaffListRef on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _StaffListProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with StaffListRef {
  _StaffListProviderElement(super.provider);

  @override
  String get storeId => (origin as StaffListProvider).storeId;
}

String _$staffActionsHash() => r'0806951be4225a4abbb52de51de8c5ec57433e01';

/// See also [StaffActions].
@ProviderFor(StaffActions)
final staffActionsProvider =
    AutoDisposeNotifierProvider<StaffActions, void>.internal(
  StaffActions.new,
  name: r'staffActionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$staffActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StaffActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
