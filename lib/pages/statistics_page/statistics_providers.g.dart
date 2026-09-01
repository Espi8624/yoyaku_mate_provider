// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statisticsServiceHash() => r'40b216693ba990ae7d9864f261db0690a8862c02';

/// See also [statisticsService].
@ProviderFor(statisticsService)
final statisticsServiceProvider =
    AutoDisposeProvider<StatisticsService>.internal(
  statisticsService,
  name: r'statisticsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statisticsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatisticsServiceRef = AutoDisposeProviderRef<StatisticsService>;
String _$statisticsDataHash() => r'f3895b77d74b0702d6dfba7b94bbca2957105417';

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

/// See also [statisticsData].
@ProviderFor(statisticsData)
const statisticsDataProvider = StatisticsDataFamily();

/// See also [statisticsData].
class StatisticsDataFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [statisticsData].
  const StatisticsDataFamily();

  /// See also [statisticsData].
  StatisticsDataProvider call({
    required String storeId,
    required String period,
    required DateTime date,
  }) {
    return StatisticsDataProvider(
      storeId: storeId,
      period: period,
      date: date,
    );
  }

  @override
  StatisticsDataProvider getProviderOverride(
    covariant StatisticsDataProvider provider,
  ) {
    return call(
      storeId: provider.storeId,
      period: provider.period,
      date: provider.date,
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
  String? get name => r'statisticsDataProvider';
}

/// See also [statisticsData].
class StatisticsDataProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [statisticsData].
  StatisticsDataProvider({
    required String storeId,
    required String period,
    required DateTime date,
  }) : this._internal(
          (ref) => statisticsData(
            ref as StatisticsDataRef,
            storeId: storeId,
            period: period,
            date: date,
          ),
          from: statisticsDataProvider,
          name: r'statisticsDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statisticsDataHash,
          dependencies: StatisticsDataFamily._dependencies,
          allTransitiveDependencies:
              StatisticsDataFamily._allTransitiveDependencies,
          storeId: storeId,
          period: period,
          date: date,
        );

  StatisticsDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storeId,
    required this.period,
    required this.date,
  }) : super.internal();

  final String storeId;
  final String period;
  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(StatisticsDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatisticsDataProvider._internal(
        (ref) => create(ref as StatisticsDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storeId: storeId,
        period: period,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _StatisticsDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatisticsDataProvider &&
        other.storeId == storeId &&
        other.period == period &&
        other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storeId.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatisticsDataRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `storeId` of this provider.
  String get storeId;

  /// The parameter `period` of this provider.
  String get period;

  /// The parameter `date` of this provider.
  DateTime get date;
}

class _StatisticsDataProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with StatisticsDataRef {
  _StatisticsDataProviderElement(super.provider);

  @override
  String get storeId => (origin as StatisticsDataProvider).storeId;
  @override
  String get period => (origin as StatisticsDataProvider).period;
  @override
  DateTime get date => (origin as StatisticsDataProvider).date;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
