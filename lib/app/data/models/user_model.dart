// Menghapus ketergantungan pada json_annotation dan file yang digenerate
class UserModel {
  final String id;
  final String username;
  final String publicKey;
  final String createdAt;
  String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.publicKey,
    required this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id']) as String,
      username: json['username'] as String,
      publicKey: json['publicKey'] as String,
      createdAt: json['createdAt'] as String,
      token: json['token'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'publicKey': publicKey,
      'createdAt': createdAt,
      if (token != null) 'token': token,
    };
  }
}