import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webcrypto/webcrypto.dart';

class CryptoUtil {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Generate a key pair 
  static Future<Map<String, dynamic>> generateKeyPair() async {
    final keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    final publicKeyJwk = await keyPair.publicKey.exportJsonWebKey();
    final privateKeyJwk = await keyPair.privateKey.exportJsonWebKey();
    
    return {
      'publicKey': publicKeyJwk,
      'privateKey': privateKeyJwk,
    };
  }

  // Get private key
  static Future<EcdhPrivateKey?> getPrivateKey() async {
    try {
      final privateKeyJson = await _storage.read(key: 'private_key');
      if (privateKeyJson == null) return null;
      
      final privateKeyJwk = jsonDecode(privateKeyJson);
      return await EcdhPrivateKey.importJsonWebKey(privateKeyJwk, EllipticCurve.p256);
    } catch (e) {
      print('Error getting private key: $e');
      return null;
    }
  }

  // Import a public key from JWK format
  static Future<EcdhPublicKey?> importPublicKey(String publicKeyString) async {
    try {
      final publicKeyJwk = jsonDecode(publicKeyString);
      return await EcdhPublicKey.importJsonWebKey(publicKeyJwk, EllipticCurve.p256);
    } catch (e) {
      print('Error importing public key: $e');
      return null;
    }
  }

 
  static Future<List<int>?> deriveSharedSecret(EcdhPrivateKey privateKey, EcdhPublicKey publicKey) async {
    try {
      final sharedSecret = await privateKey.deriveBits(256, publicKey);
      return sharedSecret;
    } catch (e) {
      print('Error deriving shared secret: $e');
      return null;
    }
  }

  // enkripsi pesan
  static Future<String?> encryptMessage(String message, List<int> sharedSecret) async {
    try {
      final key = await AesGcmSecretKey.importRawKey(sharedSecret.sublist(0, 32));
      
      final iv = List<int>.generate(12, (_) => DateTime.now().microsecondsSinceEpoch % 256);
      
      // Encrypt the message
      final ciphertext = await key.encryptBytes(
        utf8.encode(message),
        iv,
      );
      
      final combined = [...iv, ...ciphertext];
      return base64.encode(combined);
    } catch (e) {
      print('Error encrypting message: $e');
      return null;
    }
  }

  static Future<String?> decryptMessage(String encryptedMessage, List<int> sharedSecret) async {
    try {
      final combined = base64.decode(encryptedMessage);
      
      final iv = combined.sublist(0, 12);
      final ciphertext = combined.sublist(12);
      
      final key = await AesGcmSecretKey.importRawKey(sharedSecret.sublist(0, 32));
      
      final plaintext = await key.decryptBytes(ciphertext, iv);
      
      return utf8.decode(plaintext);
    } catch (e) {
      print('Error decrypting message: $e');
      return null;
    }
  }
}