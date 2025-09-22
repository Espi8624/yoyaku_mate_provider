class StoreProfile {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String bizNumber;
  final String? logoUrl;
  // ★★★ 1. verificationStatus를 nullable(String?)로 변경합니다. ★★★
  final String? verificationStatus;

  StoreProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.bizNumber,
    this.logoUrl,
    this.verificationStatus,
  });

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      id: json['store_id'] as String? ?? '',
      name: json['store_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bizNumber: json['biz_number'] as String? ?? '',
      logoUrl: json['logo_url'] as String?, // API 応答に合わせてフィールド名調整
      verificationStatus: json['verification_status'] as String?,
    );
  }
}
