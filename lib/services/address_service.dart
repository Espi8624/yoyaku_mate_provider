import 'dart:convert';
import 'package:http/http.dart' as http;

class Address {
  final String prefecture;
  final String city;
  final String town;

  Address({
    required this.prefecture,
    required this.city,
    required this.town,
  });

  String get fullAddress => '$prefecture$city$town';
}

class AddressService {
  static const String _baseUrl = 'https://zipcloud.ibsnet.co.jp/api/search';

  Future<Address?> searchAddress(String zipCode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?zipcode=$zipCode'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 200 && data['results'] != null) {
          final result = (data['results'] as List).first;
          return Address(
            prefecture: result['address1'] ?? '',
            city: result['address2'] ?? '',
            town: result['address3'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      // print('Address search failed: $e');
      return null;
    }
  }
}
