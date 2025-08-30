class StoreLicense {
  final String storeId;
  final String verificationStatus;

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
