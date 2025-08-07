// Menghapus ketergantungan pada json_annotation dan file yang digenerate
class MessageModel {
  final String id;
  final String senderId;
  final String? senderUsername;
  final String? receiverId;
  final String? chatRoom;
  final String content;
  final bool delivered;
  final bool read;
  final bool pending;
  final bool failed;
  final String? deliveredAt;
  final String? readAt;
  final String createdAt;
  final String? to;
  final String? type;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderUsername,
    this.receiverId,
    this.chatRoom,
    required this.content,
    this.delivered = false,
    this.read = false,
    this.pending = false,
    this.failed = false,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
    this.to,
    this.type,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Handle sender information which might be nested
    String senderId;
    String? senderUsername;

    if (json['sender'] != null && json['sender'] is Map<String, dynamic>) {
      final senderMap = json['sender'] as Map<String, dynamic>;
      senderId = (senderMap['_id'] ?? senderMap['id']) as String;
      senderUsername = senderMap['username'] as String?;
    } else {
      senderId = json['senderId'] as String? ?? '';
    }

    return MessageModel(
      id: (json['_id'] ?? json['id']) as String,
      senderId: senderId,
      senderUsername: senderUsername,
      receiverId: json['receiverId'] as String?,
      chatRoom: json['chatRoom'] as String?,
      content: json['content'] as String,
      delivered: json['delivered'] as bool? ?? false,
      read: json['read'] as bool? ?? false,
      pending: json['pending'] as bool? ?? false,
      failed: json['failed'] as bool? ?? false,
      deliveredAt: json['deliveredAt'] as String?,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
      to: json['to'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      if (senderUsername != null) 'senderUsername': senderUsername,
      if (receiverId != null) 'receiverId': receiverId,
      if (chatRoom != null) 'chatRoom': chatRoom,
      'content': content,
      'delivered': delivered,
      'read': read,
      'pending': pending,
      'failed': failed,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
      if (readAt != null) 'readAt': readAt,
      'createdAt': createdAt,
      'to': to,
      'type': type,
    };
  }
}
