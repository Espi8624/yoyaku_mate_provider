class StoreLicense {
  final String storeId;
  final String verificationStatus;
  // 필요하다면 다른 필드도 추가할 수 있습니다 (admin_comment 등)

  StoreLicense({
    required this.storeId,
    required this.verificationStatus,
  });

  factory StoreLicense.fromJson(Map<String, dynamic> json) {
    return StoreLicense(
      storeId: json['store_id'] ?? '',
      verificationStatus: json['verification_status'] ?? 'NOT_SUBMITTED',
    );
  }
}
