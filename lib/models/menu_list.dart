import 'dart:typed_data';

class MenuListItem {
  final String id;
  final String storeId;
  final String menuId;
  final String category;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String menuStatus;
  final Uint8List? tempImageBytes;

  MenuListItem({
    required this.id,
    required this.storeId,
    required this.menuId,
    required this.category,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.menuStatus,
    this.tempImageBytes,
  });

  factory MenuListItem.fromJson(Map<String, dynamic> json) {
    return MenuListItem(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      menuId: json['menuId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      menuStatus: json['menu_status']?.toString() ?? 'available',
      tempImageBytes: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'menuId': menuId,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'image': imageUrl, // 서버에서는 'image' 키를 사용
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'menuStatus': menuStatus,
    };
  }
}
