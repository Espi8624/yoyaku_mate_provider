class StoreProfile {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String bizNumber;
  final String? storeImageUrl;
  final String? verificationStatus;
  final String? staffStatus; // 職員の承認状態 (See [StaffStatus])

  StoreProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.bizNumber,
    this.storeImageUrl,
    this.verificationStatus,
    this.staffStatus,
  });

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      id: json['store_id'] as String? ?? '',
      name: json['store_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bizNumber: json['biz_number'] as String? ?? '',
      storeImageUrl: json['store_image_url'] as String?, // API 応答に合わせてフィールド名調整
      verificationStatus: json['verification_status'] as String?,
      staffStatus: json['staff_status'] as String?, // 職員承認状態
    );
  }
}
