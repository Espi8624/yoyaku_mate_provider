// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_management_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$menuServiceHash() => r'a0912ffc49dd9444597763bcc80a6747860957e7';

/// See also [menuService].
@ProviderFor(menuService)
final menuServiceProvider = AutoDisposeProvider<MenuService>.internal(
  menuService,
  name: r'menuServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$menuServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MenuServiceRef = AutoDisposeProviderRef<MenuService>;
String _$menuItemsNotifierHash() => r'2974bdda327fdef5cd6ba1ec6cba9f71ecdd2534';

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

abstract class _$MenuItemsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<MenuManagementData> {
  late final String storeId;

  FutureOr<MenuManagementData> build({
    required String storeId,
  });
}

/// See also [MenuItemsNotifier].
@ProviderFor(MenuItemsNotifier)
const menuItemsNotifierProvider = MenuItemsNotifierFamily();

/// See also [MenuItemsNotifier].
class MenuItemsNotifierFamily extends Family<AsyncValue<MenuManagementData>> {
  /// See also [MenuItemsNotifier].
  const MenuItemsNotifierFamily();

  /// See also [MenuItemsNotifier].
  MenuItemsNotifierProvider call({
    required String storeId,
  }) {
    return MenuItemsNotifierProvider(
      storeId: storeId,
    );
  }

  @override
  MenuItemsNotifierProvider getProviderOverride(
    covariant MenuItemsNotifierProvider provider,
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
  String? get name => r'menuItemsNotifierProvider';
}

/// See also [MenuItemsNotifier].
class MenuItemsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MenuItemsNotifier, MenuManagementData> {
  /// See also [MenuItemsNotifier].
  MenuItemsNotifierProvider({
    required String storeId,
  }) : this._internal(
          () => MenuItemsNotifier()..storeId = storeId,
          from: menuItemsNotifierProvider,
          name: r'menuItemsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$menuItemsNotifierHash,
          dependencies: MenuItemsNotifierFamily._dependencies,
          allTransitiveDependencies:
              MenuItemsNotifierFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  MenuItemsNotifierProvider._internal(
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
  FutureOr<MenuManagementData> runNotifierBuild(
    covariant MenuItemsNotifier notifier,
  ) {
    return notifier.build(
      storeId: storeId,
    );
  }

  @override
  Override overrideWith(MenuItemsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MenuItemsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<MenuItemsNotifier, MenuManagementData>
      createElement() {
    return _MenuItemsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MenuItemsNotifierProvider && other.storeId == storeId;
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
mixin MenuItemsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<MenuManagementData> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _MenuItemsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MenuItemsNotifier,
        MenuManagementData> with MenuItemsNotifierRef {
  _MenuItemsNotifierProviderElement(super.provider);

  @override
  String get storeId => (origin as MenuItemsNotifierProvider).storeId;
}

String _$menuSaveStatusHash() => r'f77008b30f0a4f04287568a9cbf1b10acebef5bc';

/// See also [MenuSaveStatus].
@ProviderFor(MenuSaveStatus)
final menuSaveStatusProvider =
    AutoDisposeNotifierProvider<MenuSaveStatus, SaveStatus>.internal(
  MenuSaveStatus.new,
  name: r'menuSaveStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$menuSaveStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MenuSaveStatus = AutoDisposeNotifier<SaveStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
