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
        menuStatus
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
      tempImageBytes:
          clearTempImage ? null : tempImageBytes ?? this.tempImageBytes,
    );
  }

  factory MenuListItem.fromJson(Map<String, dynamic> json) {
    return MenuListItem(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      menuId: json['menuId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      menuImageUrl: json['menuImageUrl']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      menuStatus: json['menuStatus']?.toString() ?? 'available',
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
      'menu_image_url': menuImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'menuStatus': menuStatus,
    };
  }
}
