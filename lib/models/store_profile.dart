class StoreProfile {
  final String name;
  final String address;
  final String phone;
  final String bizNumber;
  final String? logoUrl;

  StoreProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.bizNumber,
    this.logoUrl,
  });

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      name: json['store_name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      bizNumber: json['biz_number'] ?? '',
      logoUrl: json['logo_url'], // API 応答に合わせてフィールド名調整
    );
  }
}