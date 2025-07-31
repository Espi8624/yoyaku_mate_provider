class ProviderProfile {
  final String firebaseUid;
  final String email;
  final String phoneNumber;
  final String name;
  final String role; // 'manager' or 'staff'
  final String? storeId; // Optional for staff, required for manager  
  final String? storeName;
  final String? storeAddress;
  final String? storeTelNumber;
  final String? storeEmail;
  final String? bizNumber;
  final String? description;

  ProviderProfile({
    required this.firebaseUid,
    required this.email,
    required this.phoneNumber,
    required this.name,
    required this.role,
    this.storeId,
    this.storeName,
    this.storeAddress,
    this.storeTelNumber,
    this.storeEmail,
    this.bizNumber,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'firebase_uid': firebaseUid,
    'email': email,
    'phone_number': phoneNumber,
    'name': name,
    'role': role,
    if (storeId != null) 'store_id': storeId,
    if (storeName != null) 'store_name': storeName,
    if (storeAddress != null) 'store_address': storeAddress,
    if (storeTelNumber != null) 'store_tel_number': storeTelNumber,
    if (storeEmail != null) 'store_email': storeEmail,
    if (bizNumber != null) 'biz_number': bizNumber,
    if (description != null) 'description': description,
  };

  factory ProviderProfile.fromJson(Map<String, dynamic> json) => ProviderProfile(
    firebaseUid: json['firebase_uid'],
    email: json['email'],
    phoneNumber: json['phone_number'],
    name: json['name'],
    role: json['role'],
    // storeId: json['store_id'],
    storeName: json['store_name'],
    storeAddress: json['store_address'],
    storeTelNumber: json['store_tel_number'],
    storeEmail: json['store_email'],
    bizNumber: json['biz_number'],
    description: json['description'],
  );
}
