import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'user_storage.dart';

class ApiProvider {
  static const String baseUrl = 'http://10.247.215.236:8081';
  final UserStorage _userStorage = UserStorage();

  Future<String?> getToken() async {
    return await _userStorage.getToken();
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Unauthorized - token expired or invalid
      _userStorage.clearUser();
      Get.offAllNamed(AppRoutes.login);
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  void _handleError(dynamic error) {
    print('API Error: $error');
    throw error;
  }
}