class StoreSettings {
  final String storeId;
  final String managerId;
  final Map<String, Map<String, String>> operatingHours;
  final ClosedDays closedDays;
  final WaitingPolicy waitingPolicy;

  StoreSettings({
    required this.storeId,
    required this.managerId,
    required this.operatingHours,
    required this.closedDays,
    required this.waitingPolicy,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeId: json['store_id'] ?? '',
      managerId: json['manager_id'] ?? '',
      operatingHours: (json['settings']['operating_hours'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Map<String, String>.from(v)),
      ),
      closedDays: ClosedDays.fromJson(json['settings']['closed_days'] ?? {}),
      waitingPolicy: WaitingPolicy.fromJson(json['settings']['waiting_policy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'store_id': storeId,
    'manager_id': managerId,
    'settings': {
      'operating_hours': operatingHours,
      'closed_days': closedDays.toJson(),
      'waiting_policy': waitingPolicy.toJson(),
    },
  };

  StoreSettings copyWith({
    String? storeId,
    String? managerId,
    Map<String, Map<String, String>>? operatingHours,
    ClosedDays? closedDays,
    WaitingPolicy? waitingPolicy,
  }) {
    return StoreSettings(
      storeId: storeId ?? this.storeId,
      managerId: managerId ?? this.managerId,
      operatingHours: operatingHours ?? this.operatingHours,
      closedDays: closedDays ?? this.closedDays,
      waitingPolicy: waitingPolicy ?? this.waitingPolicy,
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
}

class WaitingPolicy {
  final int maxWaitingCount;
  WaitingPolicy({required this.maxWaitingCount});

  factory WaitingPolicy.fromJson(Map<String, dynamic> json) {
    return WaitingPolicy(maxWaitingCount: json['max_waiting_count'] ?? 0);
  }

  Map<String, dynamic> toJson() => {
    'max_waiting_count': maxWaitingCount,
  };

  WaitingPolicy copyWith({int? maxWaitingCount}) {
    return WaitingPolicy(
      maxWaitingCount: maxWaitingCount ?? this.maxWaitingCount,
    );
  }
}
