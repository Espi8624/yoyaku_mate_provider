// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_table_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shiftTableHash() => r'83203683db2240b80f1edf58c5e7e7d719acee87';

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

/// See also [shiftTable].
@ProviderFor(shiftTable)
const shiftTableProvider = ShiftTableFamily();

/// See also [shiftTable].
class ShiftTableFamily extends Family<AsyncValue<ShiftTable?>> {
  /// See also [shiftTable].
  const ShiftTableFamily();

  /// See also [shiftTable].
  ShiftTableProvider call({
    required String storeId,
    required String weekStartDate,
  }) {
    return ShiftTableProvider(
      storeId: storeId,
      weekStartDate: weekStartDate,
    );
  }

  @override
  ShiftTableProvider getProviderOverride(
    covariant ShiftTableProvider provider,
  ) {
    return call(
      storeId: provider.storeId,
      weekStartDate: provider.weekStartDate,
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
  String? get name => r'shiftTableProvider';
}

/// See also [shiftTable].
class ShiftTableProvider extends AutoDisposeFutureProvider<ShiftTable?> {
  /// See also [shiftTable].
  ShiftTableProvider({
    required String storeId,
    required String weekStartDate,
  }) : this._internal(
          (ref) => shiftTable(
            ref as ShiftTableRef,
            storeId: storeId,
            weekStartDate: weekStartDate,
          ),
          from: shiftTableProvider,
          name: r'shiftTableProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shiftTableHash,
          dependencies: ShiftTableFamily._dependencies,
          allTransitiveDependencies:
              ShiftTableFamily._allTransitiveDependencies,
          storeId: storeId,
          weekStartDate: weekStartDate,
        );

  ShiftTableProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storeId,
    required this.weekStartDate,
  }) : super.internal();

  final String storeId;
  final String weekStartDate;

  @override
  Override overrideWith(
    FutureOr<ShiftTable?> Function(ShiftTableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShiftTableProvider._internal(
        (ref) => create(ref as ShiftTableRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storeId: storeId,
        weekStartDate: weekStartDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ShiftTable?> createElement() {
    return _ShiftTableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftTableProvider &&
        other.storeId == storeId &&
        other.weekStartDate == weekStartDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storeId.hashCode);
    hash = _SystemHash.combine(hash, weekStartDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShiftTableRef on AutoDisposeFutureProviderRef<ShiftTable?> {
  /// The parameter `storeId` of this provider.
  String get storeId;

  /// The parameter `weekStartDate` of this provider.
  String get weekStartDate;
}

class _ShiftTableProviderElement
    extends AutoDisposeFutureProviderElement<ShiftTable?> with ShiftTableRef {
  _ShiftTableProviderElement(super.provider);

  @override
  String get storeId => (origin as ShiftTableProvider).storeId;
  @override
  String get weekStartDate => (origin as ShiftTableProvider).weekStartDate;
}

String _$shiftChangeRequestsHash() =>
    r'4212094f8c6aa9e79193d09fd32889f5c581d96d';

/// See also [shiftChangeRequests].
@ProviderFor(shiftChangeRequests)
const shiftChangeRequestsProvider = ShiftChangeRequestsFamily();

/// See also [shiftChangeRequests].
class ShiftChangeRequestsFamily
    extends Family<AsyncValue<List<ShiftChangeRequest>>> {
  /// See also [shiftChangeRequests].
  const ShiftChangeRequestsFamily();

  /// See also [shiftChangeRequests].
  ShiftChangeRequestsProvider call({
    required String storeId,
    required String weekStartDate,
  }) {
    return ShiftChangeRequestsProvider(
      storeId: storeId,
      weekStartDate: weekStartDate,
    );
  }

  @override
  ShiftChangeRequestsProvider getProviderOverride(
    covariant ShiftChangeRequestsProvider provider,
  ) {
    return call(
      storeId: provider.storeId,
      weekStartDate: provider.weekStartDate,
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
  String? get name => r'shiftChangeRequestsProvider';
}

/// See also [shiftChangeRequests].
class ShiftChangeRequestsProvider
    extends AutoDisposeFutureProvider<List<ShiftChangeRequest>> {
  /// See also [shiftChangeRequests].
  ShiftChangeRequestsProvider({
    required String storeId,
    required String weekStartDate,
  }) : this._internal(
          (ref) => shiftChangeRequests(
            ref as ShiftChangeRequestsRef,
            storeId: storeId,
            weekStartDate: weekStartDate,
          ),
          from: shiftChangeRequestsProvider,
          name: r'shiftChangeRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shiftChangeRequestsHash,
          dependencies: ShiftChangeRequestsFamily._dependencies,
          allTransitiveDependencies:
              ShiftChangeRequestsFamily._allTransitiveDependencies,
          storeId: storeId,
          weekStartDate: weekStartDate,
        );

  ShiftChangeRequestsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storeId,
    required this.weekStartDate,
  }) : super.internal();

  final String storeId;
  final String weekStartDate;

  @override
  Override overrideWith(
    FutureOr<List<ShiftChangeRequest>> Function(ShiftChangeRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShiftChangeRequestsProvider._internal(
        (ref) => create(ref as ShiftChangeRequestsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storeId: storeId,
        weekStartDate: weekStartDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ShiftChangeRequest>> createElement() {
    return _ShiftChangeRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftChangeRequestsProvider &&
        other.storeId == storeId &&
        other.weekStartDate == weekStartDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storeId.hashCode);
    hash = _SystemHash.combine(hash, weekStartDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShiftChangeRequestsRef
    on AutoDisposeFutureProviderRef<List<ShiftChangeRequest>> {
  /// The parameter `storeId` of this provider.
  String get storeId;

  /// The parameter `weekStartDate` of this provider.
  String get weekStartDate;
}

class _ShiftChangeRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<ShiftChangeRequest>>
    with ShiftChangeRequestsRef {
  _ShiftChangeRequestsProviderElement(super.provider);

  @override
  String get storeId => (origin as ShiftChangeRequestsProvider).storeId;
  @override
  String get weekStartDate =>
      (origin as ShiftChangeRequestsProvider).weekStartDate;
}

String _$shiftActionsHash() => r'27da0c83931a9569214b2053cbb539ee5af53d1e';

/// See also [ShiftActions].
@ProviderFor(ShiftActions)
final shiftActionsProvider =
    AutoDisposeNotifierProvider<ShiftActions, void>.internal(
  ShiftActions.new,
  name: r'shiftActionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$shiftActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ShiftActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
