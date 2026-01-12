import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class MenuListItem extends Equatable {
  final String id;
  final String storeId;
  final String menuId;
  final String category;
  final String title;
  final String description;
  final double price;
  final String menuImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String menuStatus;
  final bool isPreOrderAvailable;
  final Uint8List? tempImageBytes;

  const MenuListItem({
    required this.id,
    required this.storeId,
    required this.menuId,
    required this.category,
    required this.title,
    required this.description,
    required this.price,
    required this.menuImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.menuStatus,
    this.isPreOrderAvailable = false,
    this.tempImageBytes,
  });

  @override
  List<Object?> get props => [
        id,
        storeId,
        menuId,
        category,
        title,
        description,
        price,
        menuImageUrl,
        createdAt,
        updatedAt,
        updatedAt,
        menuStatus,
        isPreOrderAvailable,
      ];

  MenuListItem copyWith({
    String? id,
    String? storeId,
    String? menuId,
    String? category,
    String? title,
    String? description,
    double? price,
    String? menuImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? menuStatus,
    bool? isPreOrderAvailable,
    Uint8List? tempImageBytes,
    bool clearTempImage = false,
  }) {
    return MenuListItem(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      menuId: menuId ?? this.menuId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      menuImageUrl: menuImageUrl ?? this.menuImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      menuStatus: menuStatus ?? this.menuStatus,
      isPreOrderAvailable: isPreOrderAvailable ?? this.isPreOrderAvailable,
      tempImageBytes:
          clearTempImage ? null : tempImageBytes ?? this.tempImageBytes,
    );
  }

  factory MenuListItem.fromJson(Map<String, dynamic> json) {
    return MenuListItem(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      menuId: json['menu_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      menuImageUrl: json['menu_image_url']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      menuStatus: json['menu_status']?.toString() ?? 'available',
      isPreOrderAvailable: json['is_pre_order_available'] ?? false,
      tempImageBytes: null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'store_id': storeId,
      'menu_id': menuId,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'menu_status': menuStatus,
      'is_pre_order_available': isPreOrderAvailable,
      'menu_image_url': menuImageUrl,
    };

    // menu_image_urlが空でない場合のみ追加
    if (menuImageUrl.isNotEmpty) {
      json['menu_image_url'] = menuImageUrl;
    }

    return json;
  }
}
