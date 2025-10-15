class UserProfile {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? userImageUrl;
  final String? storeId;

  UserProfile(
      {required this.id,
      required this.name,
      required this.role,
      required this.email,
      required this.phone,
      this.userImageUrl,
      this.storeId});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['user_name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userImageUrl: json['user_image_url'], // API 応答に合わせてフィールド名調整
      storeId: json['store_id']?.toString(),
    );
  }

  // フィールドアップデートをするための copyWith メソッド
  UserProfile copyWith({String? name, String? email, String? phone}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      role: role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userImageUrl: userImageUrl,
      // storeId: this.storeId,
    );
  }
}
