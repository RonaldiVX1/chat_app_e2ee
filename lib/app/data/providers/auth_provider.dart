import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webcrypto/webcrypto.dart';
import '../models/user_model.dart';
import 'api_provider.dart';
import 'user_storage.dart';

class AuthProvider {
  final ApiProvider _apiProvider = ApiProvider();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final UserStorage _userStorage = UserStorage();

  Future<UserModel?> register(String username, String password) async {
    try {
      // Generate key pair from password
      final keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
      final publicKey = await keyPair.publicKey.exportJsonWebKey();
      final publicKeyString = jsonEncode(publicKey);
      
      final privateKeyJwk = await keyPair.privateKey.exportJsonWebKey();
      await _storage.write(key: 'private_key', value: jsonEncode(privateKeyJwk));
      
      final data = {
        'username': username,
        'password': password,
        'publicKey': publicKeyString,
      };
      
      final response = await _apiProvider.post('/register', data);
      
      if (response != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        user.token = response['token'];
        
        await _userStorage.saveUser(user);
        
        return user;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  Future<UserModel?> login(String username, String password) async {
    try {
      final data = {
        'username': username,
        'password': password,
      };
      
      final response = await _apiProvider.post('/login', data);
      
      if (response != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        user.token = response['token'];
        
        await _userStorage.saveUser(user);
        
        return user;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _userStorage.clearUser();
  }

  Future<UserModel?> getCurrentUser() async {
    return await _userStorage.getUser();
  }
}