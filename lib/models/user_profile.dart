class UserProfile {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone_number;
  final String? userImageUrl;
  final String? storeId;

  UserProfile(
      {required this.id,
      required this.name,
      required this.role,
      required this.email,
      required this.phone_number,
      this.userImageUrl,
      this.storeId});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['user_name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      phone_number: json['phone_number'] ?? json['phone'] ?? '',
      userImageUrl: json['user_image_url'], // API 応答に合わせてフィールド名調整
      storeId: json['store_id']?.toString(),
    );
  }

  // フィールドアップデートをするための copyWith メソッド
  UserProfile copyWith({String? name, String? email, String? phone_number}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      role: role,
      email: email ?? this.email,
      phone_number: phone_number ?? this.phone_number,
      userImageUrl: userImageUrl,
      // storeId: this.storeId,
    );
  }
}
