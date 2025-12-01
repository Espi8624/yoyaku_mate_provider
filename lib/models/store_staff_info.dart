class StoreStaffInfo {
  final String id;
  final String userId;
  final String storeId;
  final String role;
  final String status; // See [StaffStatus]
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreStaffInfo({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreStaffInfo.fromJson(Map<String, dynamic> json) {
    return StoreStaffInfo(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      storeId: json['store_id'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'store_id': storeId,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
