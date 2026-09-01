// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileServiceHash() => r'3621133f02dcc207df41fd601e4a556eac368410';

/// See also [profileService].
@ProviderFor(profileService)
final profileServiceProvider =
    AutoDisposeProvider<ProviderProfileService>.internal(
  profileService,
  name: r'profileServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileServiceRef = AutoDisposeProviderRef<ProviderProfileService>;
String _$storeSettingsServiceHash() =>
    r'd2dc29f5650aa609fdebcfbd32addf7e18202568';

/// See also [storeSettingsService].
@ProviderFor(storeSettingsService)
final storeSettingsServiceProvider =
    AutoDisposeProvider<StoreSettingsService>.internal(
  storeSettingsService,
  name: r'storeSettingsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storeSettingsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StoreSettingsServiceRef = AutoDisposeProviderRef<StoreSettingsService>;
String _$firebaseUserHash() => r'41ccd6f03a5c4ed94888741812ccad955176fcc0';

/// See also [firebaseUser].
@ProviderFor(firebaseUser)
final firebaseUserProvider = AutoDisposeStreamProvider<User?>.internal(
  firebaseUser,
  name: r'firebaseUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseUserRef = AutoDisposeStreamProviderRef<User?>;
String _$appInfoHash() => r'd8df58519aeeda7c30f477a57d5fd3989e59a2aa';

/// See also [appInfo].
@ProviderFor(appInfo)
final appInfoProvider = AutoDisposeFutureProvider<PackageInfo>.internal(
  appInfo,
  name: r'appInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppInfoRef = AutoDisposeFutureProviderRef<PackageInfo>;
String _$userProfileHash() => r'cab48021f192c2f7c5fb5a2a1b466aeb7b19c225';

/// See also [userProfile].
@ProviderFor(userProfile)
final userProfileProvider = AutoDisposeFutureProvider<UserProfile>.internal(
  userProfile,
  name: r'userProfileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRef = AutoDisposeFutureProviderRef<UserProfile>;
String _$myStoresHash() => r'8132807f542a94c810cc6a2a311e9b2e689e362b';

/// See also [myStores].
@ProviderFor(myStores)
final myStoresProvider = AutoDisposeFutureProvider<List<StoreProfile>>.internal(
  myStores,
  name: r'myStoresProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myStoresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyStoresRef = AutoDisposeFutureProviderRef<List<StoreProfile>>;
String _$selectedStoreProfileHash() =>
    r'a081ce236addfab1ec49202d75ce52cb82e3b6db';

/// See also [selectedStoreProfile].
@ProviderFor(selectedStoreProfile)
final selectedStoreProfileProvider =
    AutoDisposeProvider<StoreProfile?>.internal(
  selectedStoreProfile,
  name: r'selectedStoreProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedStoreProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SelectedStoreProfileRef = AutoDisposeProviderRef<StoreProfile?>;
String _$storeLicenseHash() => r'246aac74ffe73b18853f102ffaf3408c4ae921b2';

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

/// See also [storeLicense].
@ProviderFor(storeLicense)
const storeLicenseProvider = StoreLicenseFamily();

/// See also [storeLicense].
class StoreLicenseFamily extends Family<AsyncValue<StoreLicense?>> {
  /// See also [storeLicense].
  const StoreLicenseFamily();

  /// See also [storeLicense].
  StoreLicenseProvider call({
    required String storeId,
  }) {
    return StoreLicenseProvider(
      storeId: storeId,
    );
  }

  @override
  StoreLicenseProvider getProviderOverride(
    covariant StoreLicenseProvider provider,
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
  String? get name => r'storeLicenseProvider';
}

/// See also [storeLicense].
class StoreLicenseProvider extends AutoDisposeFutureProvider<StoreLicense?> {
  /// See also [storeLicense].
  StoreLicenseProvider({
    required String storeId,
  }) : this._internal(
          (ref) => storeLicense(
            ref as StoreLicenseRef,
            storeId: storeId,
          ),
          from: storeLicenseProvider,
          name: r'storeLicenseProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$storeLicenseHash,
          dependencies: StoreLicenseFamily._dependencies,
          allTransitiveDependencies:
              StoreLicenseFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  StoreLicenseProvider._internal(
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
    FutureOr<StoreLicense?> Function(StoreLicenseRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StoreLicenseProvider._internal(
        (ref) => create(ref as StoreLicenseRef),
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
  AutoDisposeFutureProviderElement<StoreLicense?> createElement() {
    return _StoreLicenseProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StoreLicenseProvider && other.storeId == storeId;
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
mixin StoreLicenseRef on AutoDisposeFutureProviderRef<StoreLicense?> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _StoreLicenseProviderElement
    extends AutoDisposeFutureProviderElement<StoreLicense?>
    with StoreLicenseRef {
  _StoreLicenseProviderElement(super.provider);

  @override
  String get storeId => (origin as StoreLicenseProvider).storeId;
}

String _$storeSettingsHash() => r'49232d96e4d4dfe122736994760c51cf0da376f5';

/// See also [storeSettings].
@ProviderFor(storeSettings)
const storeSettingsProvider = StoreSettingsFamily();

/// See also [storeSettings].
class StoreSettingsFamily extends Family<AsyncValue<StoreSettings?>> {
  /// See also [storeSettings].
  const StoreSettingsFamily();

  /// See also [storeSettings].
  StoreSettingsProvider call({
    required String storeId,
  }) {
    return StoreSettingsProvider(
      storeId: storeId,
    );
  }

  @override
  StoreSettingsProvider getProviderOverride(
    covariant StoreSettingsProvider provider,
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
  String? get name => r'storeSettingsProvider';
}

/// See also [storeSettings].
class StoreSettingsProvider extends AutoDisposeFutureProvider<StoreSettings?> {
  /// See also [storeSettings].
  StoreSettingsProvider({
    required String storeId,
  }) : this._internal(
          (ref) => storeSettings(
            ref as StoreSettingsRef,
            storeId: storeId,
          ),
          from: storeSettingsProvider,
          name: r'storeSettingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$storeSettingsHash,
          dependencies: StoreSettingsFamily._dependencies,
          allTransitiveDependencies:
              StoreSettingsFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  StoreSettingsProvider._internal(
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
    FutureOr<StoreSettings?> Function(StoreSettingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StoreSettingsProvider._internal(
        (ref) => create(ref as StoreSettingsRef),
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
  AutoDisposeFutureProviderElement<StoreSettings?> createElement() {
    return _StoreSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StoreSettingsProvider && other.storeId == storeId;
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
mixin StoreSettingsRef on AutoDisposeFutureProviderRef<StoreSettings?> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _StoreSettingsProviderElement
    extends AutoDisposeFutureProviderElement<StoreSettings?>
    with StoreSettingsRef {
  _StoreSettingsProviderElement(super.provider);

  @override
  String get storeId => (origin as StoreSettingsProvider).storeId;
}

String _$myAvailabilityHash() => r'4531189d612a6767af9d3398fc9bdd4e46a2e389';

/// See also [myAvailability].
@ProviderFor(myAvailability)
const myAvailabilityProvider = MyAvailabilityFamily();

/// See also [myAvailability].
class MyAvailabilityFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [myAvailability].
  const MyAvailabilityFamily();

  /// See also [myAvailability].
  MyAvailabilityProvider call({
    required String storeId,
  }) {
    return MyAvailabilityProvider(
      storeId: storeId,
    );
  }

  @override
  MyAvailabilityProvider getProviderOverride(
    covariant MyAvailabilityProvider provider,
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
  String? get name => r'myAvailabilityProvider';
}

/// See also [myAvailability].
class MyAvailabilityProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [myAvailability].
  MyAvailabilityProvider({
    required String storeId,
  }) : this._internal(
          (ref) => myAvailability(
            ref as MyAvailabilityRef,
            storeId: storeId,
          ),
          from: myAvailabilityProvider,
          name: r'myAvailabilityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$myAvailabilityHash,
          dependencies: MyAvailabilityFamily._dependencies,
          allTransitiveDependencies:
              MyAvailabilityFamily._allTransitiveDependencies,
          storeId: storeId,
        );

  MyAvailabilityProvider._internal(
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
    FutureOr<Map<String, dynamic>> Function(MyAvailabilityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MyAvailabilityProvider._internal(
        (ref) => create(ref as MyAvailabilityRef),
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
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _MyAvailabilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyAvailabilityProvider && other.storeId == storeId;
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
mixin MyAvailabilityRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `storeId` of this provider.
  String get storeId;
}

class _MyAvailabilityProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with MyAvailabilityRef {
  _MyAvailabilityProviderElement(super.provider);

  @override
  String get storeId => (origin as MyAvailabilityProvider).storeId;
}

String _$selectedStoreIdHash() => r'ab359076264b0abc8a2eb0ee420efcbef20bd63b';

/// See also [SelectedStoreId].
@ProviderFor(SelectedStoreId)
final selectedStoreIdProvider =
    AutoDisposeNotifierProvider<SelectedStoreId, String?>.internal(
  SelectedStoreId.new,
  name: r'selectedStoreIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedStoreIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedStoreId = AutoDisposeNotifier<String?>;
String _$profileActionsHash() => r'65490653ed1b487fb0c16848700a4f9059dcf832';

/// See also [ProfileActions].
@ProviderFor(ProfileActions)
final profileActionsProvider =
    AutoDisposeNotifierProvider<ProfileActions, void>.internal(
  ProfileActions.new,
  name: r'profileActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileActions = AutoDisposeNotifier<void>;
String _$storeActionsHash() => r'4321241efd50bde9fba86308cbb22424caabddf2';

/// See also [StoreActions].
@ProviderFor(StoreActions)
final storeActionsProvider =
    AutoDisposeNotifierProvider<StoreActions, void>.internal(
  StoreActions.new,
  name: r'storeActionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$storeActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StoreActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
