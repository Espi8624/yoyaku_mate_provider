class StoreProfile {
  final String id;
  final String name;
  final String address;
  final String? zipCode; // New
  final String? prefecture; // New
  final String? city; // New
  final String? building;
  final String phone_number;
  final String bizNumber;
  final String? storeImageUrl;
  final String? verificationStatus;
  final String? staffStatus; // 職員の承認状態 (See [StaffStatus])

  StoreProfile({
    required this.id,
    required this.name,
    required this.address,
    this.zipCode, // New
    this.prefecture, // New
    this.city, // New
    this.building,
    required this.phone_number,
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
      zipCode: json['zip_code'] as String?, // New
      prefecture: json['prefecture'] as String?, // New
      city: json['city'] as String?, // New
      building: json['building'] as String?,
      phone_number:
          json['phone_number'] as String? ?? json['phone'] as String? ?? '',
      bizNumber: json['biz_number'] as String? ?? '',
      storeImageUrl: json['store_image_url'] as String?, // API 応答に合わせてフィールド名調整
      verificationStatus: json['verification_status'] as String?,
      staffStatus: json['staff_status'] as String?, // 職員承認状態
    );
  }
}
