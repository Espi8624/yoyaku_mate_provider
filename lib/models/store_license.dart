class StoreLicense {
  final String storeId;
  final String verificationStatus;
  final String? imageUrl;

  StoreLicense({
    required this.storeId,
    required this.verificationStatus,
    this.imageUrl,
  });

  factory StoreLicense.fromJson(Map<String, dynamic> json) {
    return StoreLicense(
      storeId: json['store_id'] ?? '',
      verificationStatus: json['verification_status'] ?? 'NOT_SUBMITTED',
      imageUrl: json['image_url'],
    );
  }
}
