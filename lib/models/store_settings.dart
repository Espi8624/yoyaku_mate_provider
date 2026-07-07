class StoreSettings {
  final String storeId;
  final String managerId;
  final Map<String, Map<String, String>> operatingHours;
  final ClosedDays closedDays;
  final WaitingPolicy waitingPolicy;
  final bool is24Hours;
  final String resetTime;
  final String aiAdditionalInfo;

  StoreSettings({
    required this.storeId,
    required this.managerId,
    required this.operatingHours,
    required this.closedDays,
    required this.waitingPolicy,
    this.is24Hours = false,
    this.resetTime = '06:00',
    this.aiAdditionalInfo = '',
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeId: json['store_id'] ?? '',
      managerId: json['manager_id'] ?? '',
      operatingHours:
          (json['settings']['operating_hours'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Map<String, String>.from(v)),
      ),
      closedDays: ClosedDays.fromJson(json['settings']['closed_days'] ?? {}),
      waitingPolicy:
          WaitingPolicy.fromJson(json['settings']['waiting_policy'] ?? {}),
      is24Hours: json['settings']['is_24_hours'] ?? false,
      resetTime: json['settings']['reset_time'] ?? '06:00',
      aiAdditionalInfo: json['settings']['ai_additional_info'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'store_id': storeId,
        'manager_id': managerId,
        'settings': {
          'operating_hours': operatingHours,
          'closed_days': closedDays.toJson(),
          'waiting_policy': waitingPolicy.toJson(),
          'is_24_hours': is24Hours,
          'reset_time': resetTime,
          'ai_additional_info': aiAdditionalInfo,
        },
      };

  StoreSettings copyWith({
    String? storeId,
    String? managerId,
    Map<String, Map<String, String>>? operatingHours,
    ClosedDays? closedDays,
    WaitingPolicy? waitingPolicy,
    bool? is24Hours,
    String? resetTime,
    String? aiAdditionalInfo,
  }) {
    return StoreSettings(
      storeId: storeId ?? this.storeId,
      managerId: managerId ?? this.managerId,
      operatingHours: operatingHours ?? this.operatingHours,
      closedDays: closedDays ?? this.closedDays,
      waitingPolicy: waitingPolicy ?? this.waitingPolicy,
      is24Hours: is24Hours ?? this.is24Hours,
      resetTime: resetTime ?? this.resetTime,
      aiAdditionalInfo: aiAdditionalInfo ?? this.aiAdditionalInfo,
    );
  }
}

class ClosedDays {
  final List<String> specificDates;
  final List<String> regularWeekly;
  final List<String> regularMonthly;
  final bool holidayClosure;

  ClosedDays({
    required this.specificDates,
    required this.regularWeekly,
    required this.regularMonthly,
    required this.holidayClosure,
  });

  factory ClosedDays.fromJson(Map<String, dynamic> json) {
    return ClosedDays(
      specificDates: List<String>.from(json['specific_dates'] ?? []),
      regularWeekly: List<String>.from(json['regular_weekly'] ?? []),
      regularMonthly: List<String>.from(json['regular_monthly'] ?? []),
      holidayClosure: json['holiday_closure'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'specific_dates': specificDates,
        'regular_weekly': regularWeekly,
        'regular_monthly': regularMonthly,
        'holiday_closure': holidayClosure,
      };

  // UI に表示する休業日要約情報を生成する getter
  String get summary {
    final parts = <String>[];

    // 毎週定期休業日情報追加
    if (regularWeekly.isNotEmpty) {
      // 、で縁結
      parts.add('毎週${regularWeekly.join('、')}');
    }

    // 祝日休業日情報追加
    if (holidayClosure) {
      parts.add('祝日');
    }

    // 特定日休業日情報追加
    if (specificDates.isNotEmpty) {
      parts.add('特定日${specificDates.length}日');
    }

    // 設定されている休業日がない場合'なし'を返却
    if (parts.isEmpty) {
      return 'なし';
    }

    // 設定されている情報を' / 'で繋げて最終文字列を生成
    return parts.join(' / ');
  }
}

class WaitingPolicy {
  final int maxWaitingCount;
  final int? estimatedWaitTime;
  final bool enableMenuSelection;
  final bool requireOneMenuPerPerson;

  WaitingPolicy({
    required this.maxWaitingCount,
    this.estimatedWaitTime,
    this.enableMenuSelection = false,
    this.requireOneMenuPerPerson = false,
  });

  factory WaitingPolicy.fromJson(Map<String, dynamic> json) {
    return WaitingPolicy(
      maxWaitingCount: json['max_waiting_count'] ?? 0,
      estimatedWaitTime: json['estimated_wait_time'] ?? 0,
      enableMenuSelection: json['enable_menu_selection'] ?? false,
      requireOneMenuPerPerson: json['require_one_menu_per_person'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'max_waiting_count': maxWaitingCount,
        'estimated_wait_time': estimatedWaitTime,
        'enable_menu_selection': enableMenuSelection,
        'require_one_menu_per_person': requireOneMenuPerPerson,
      };

  WaitingPolicy copyWith({
    int? maxWaitingCount,
    int? estimatedWaitTime,
    bool? enableMenuSelection,
    bool? requireOneMenuPerPerson,
  }) {
    return WaitingPolicy(
      maxWaitingCount: maxWaitingCount ?? this.maxWaitingCount,
      estimatedWaitTime: estimatedWaitTime ?? this.estimatedWaitTime,
      enableMenuSelection: enableMenuSelection ?? this.enableMenuSelection,
      requireOneMenuPerPerson:
          requireOneMenuPerPerson ?? this.requireOneMenuPerPerson,
    );
  }
}
