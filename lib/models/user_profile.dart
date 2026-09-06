class UserProfile {
  final String id;
  final String name;
  final String? nameFurigana;
  final String role;
  final String email;
  final String phone_number;
  final String? userImageUrl;
  final String? storeId;
  final String? birthdate; // 本人の生年月日 (YYYY-MM-DD)
  final String? zipCode; // 本人の郵便番号
  final String? prefecture; // 本人の都道府県
  final String? city; // 本人の市区町村
  final String? address; // 本人の住所(番地)
  final String? building; // 本人の建物名・部屋番号(任意)

  UserProfile({
    required this.id,
    required this.name,
    this.nameFurigana,
    required this.role,
    required this.email,
    required this.phone_number,
    this.userImageUrl,
    this.storeId,
    this.birthdate,
    this.zipCode,
    this.prefecture,
    this.city,
    this.address,
    this.building,
  });

  /// 表示用の住所全文("都道府県市区町村番地 建物名")
  String? get fullAddress {
    if (address == null || address!.isEmpty) return null;
    final trimmedBuilding = (building ?? '').trim();
    return trimmedBuilding.isEmpty ? address : '$address $trimmedBuilding';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['user_name'] ?? '',
      nameFurigana: json['name_furigana'] ?? json['user_name_furigana'],
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      phone_number: json['phone_number'] ?? json['phone'] ?? '',
      userImageUrl: json['user_image_url'],
      storeId: json['store_id']?.toString(),
      birthdate: json['birthdate'],
      zipCode: json['zip_code'],
      prefecture: json['prefecture'],
      city: json['city'],
      address: json['address'],
      building: json['building'],
    );
  }

  // フィールドアップデートをするための copyWith メソッド
  UserProfile copyWith({
    String? name,
    String? nameFurigana,
    String? email,
    String? phone_number,
    String? userImageUrl,
    String? storeId,
    String? birthdate,
    String? zipCode,
    String? prefecture,
    String? city,
    String? address,
    String? building,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      nameFurigana: nameFurigana ?? this.nameFurigana,
      role: role,
      email: email ?? this.email,
      phone_number: phone_number ?? this.phone_number,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      storeId: storeId ?? this.storeId,
      birthdate: birthdate ?? this.birthdate,
      zipCode: zipCode ?? this.zipCode,
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      address: address ?? this.address,
      building: building ?? this.building,
    );
  }
}
