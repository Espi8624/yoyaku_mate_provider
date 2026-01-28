class ProviderProfile {
  final String firebaseUid;
  final String email;
  final String phoneNumber;
  final String name;
  final String nameFurigana;
  final String role; // 'manager' または 'staff'
  final String? storeId; // スタッフは任意、マネージャーは必須
  final String? storeName;
  final String? storeAddress;
  final String? storeBuilding; // New
  final String? storeZipCode;
  final String? storePrefecture;
  final String? storeCity;
  final String? storeTelNumber;
  final String? storeEmail;
  final String? bizNumber;
  final String? description;
  final bool termsAgreed;
  final DateTime? termsAgreedAt;
  final bool privacyAgreed;
  final DateTime? privacyAgreedAt;
  final int? estimatedWaitTime;
  final int? maxWaitingCount;
  final bool? enableMenuSelection;
  final bool? requireOneMenuPerPerson; // New
  final Map<String, Map<String, String>>? operatingHours;
  final bool? is24Hours;
  final String? resetTime;

  ProviderProfile({
    required this.firebaseUid,
    required this.email,
    required this.phoneNumber,
    required this.name,
    required this.nameFurigana,
    required this.role,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.storeBuilding,
    this.storeZipCode,
    this.storePrefecture,
    this.storeCity,
    this.storeTelNumber,
    this.storeEmail,
    this.bizNumber,
    this.description,
    this.termsAgreed = false,
    this.termsAgreedAt,
    this.privacyAgreed = false,
    this.privacyAgreedAt,
    this.estimatedWaitTime,
    this.maxWaitingCount,
    this.enableMenuSelection,
    this.requireOneMenuPerPerson, // New
    this.operatingHours,
    this.is24Hours,
    this.resetTime,
  });

  Map<String, dynamic> toJson() => {
        'firebase_uid': firebaseUid,
        'email': email,
        'phone_number': phoneNumber,
        'name': name,
        'name_furigana': nameFurigana,
        'role': role,
        if (storeId != null) 'store_id': storeId,
        if (storeName != null) 'store_name': storeName,
        if (storeAddress != null) 'store_address': storeAddress,
        if (storeBuilding != null) 'store_building': storeBuilding,
        if (storeZipCode != null) 'store_zip_code': storeZipCode,
        if (storePrefecture != null) 'store_prefecture': storePrefecture,
        if (storeCity != null) 'store_city': storeCity,
        if (storeTelNumber != null) 'store_tel_number': storeTelNumber,
        if (storeEmail != null) 'store_email': storeEmail,
        if (bizNumber != null) 'biz_number': bizNumber,
        if (description != null) 'description': description,
        'terms_agreed': termsAgreed,
        if (termsAgreedAt != null)
          'terms_agreed_at': termsAgreedAt!.toIso8601String(),
        'privacy_agreed': privacyAgreed,
        if (privacyAgreedAt != null)
          'privacy_agreed_at': privacyAgreedAt!.toIso8601String(),
        if (estimatedWaitTime != null) 'estimated_wait_time': estimatedWaitTime,
        if (maxWaitingCount != null) 'max_waiting_count': maxWaitingCount,
        if (enableMenuSelection != null)
          'enable_menu_selection': enableMenuSelection,
        if (requireOneMenuPerPerson != null)
          'require_one_menu_per_person': requireOneMenuPerPerson, // New
        if (operatingHours != null) 'operating_hours': operatingHours,
        if (is24Hours != null) 'is_24_hours': is24Hours,
        if (resetTime != null) 'reset_time': resetTime,
      };

  factory ProviderProfile.fromJson(Map<String, dynamic> json) =>
      ProviderProfile(
        firebaseUid: json['firebase_uid'],
        email: json['email'],
        phoneNumber: json['phone_number'],
        name: json['name'],
        nameFurigana: json['name_furigana'],
        role: json['role'],
        // storeId: json['store_id'],
        storeName: json['store_name'],
        storeAddress: json['store_address'],
        storeTelNumber: json['store_tel_number'],
        storeEmail: json['store_email'],
        bizNumber: json['biz_number'],
        description: json['description'],
        termsAgreed: json['terms_agreed'] ?? false,
        termsAgreedAt: json['terms_agreed_at'] != null
            ? DateTime.parse(json['terms_agreed_at'])
            : null,
        privacyAgreed: json['privacy_agreed'] ?? false,
        privacyAgreedAt: json['privacy_agreed_at'] != null
            ? DateTime.parse(json['privacy_agreed_at'])
            : null,
      );
}
