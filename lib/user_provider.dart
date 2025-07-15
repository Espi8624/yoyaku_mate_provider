import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? userId;
  String? userName;
  String? userRole;
  String? storeId;
  Map<String, dynamic>? storeInfo;

  void setUserInfo(Map<String, dynamic> userInfo) {
    userId = userInfo['data']['_id'] ?? userInfo['data']['id'];
    userName = userInfo['data']['user_name'];
    userRole = userInfo['data']['role'];
    storeId = userInfo['data']['store_id'];
    notifyListeners();
  }

  void clear() {
    userId = null;
    userName = null;
    userRole = null;
    storeId = null;
    notifyListeners();
  }

  void setStoreId(String? id) {
    storeId = id;
    notifyListeners();
  }

  void setStoreInfo(Map<String, dynamic>? info) {
    storeInfo = info;
    storeId = info?['store_id'];
    notifyListeners();
  }
} 