import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class UserStorage {
  static final UserStorage _instance = UserStorage._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory UserStorage() {
    return _instance;
  }

  UserStorage._internal();

  Future<UserModel?> getUser() async {
    try {
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Get user from storage error: $e');
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
      if (user.token != null) {
        await _storage.write(key: 'token', value: user.token!);
      }
    } catch (e) {
      print('Save user to storage error: $e');
    }
  }

  Future<void> clearUser() async {
    await _storage.delete(key: 'user');
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
}