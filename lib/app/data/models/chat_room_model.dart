class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String createdAt;
  final String updatedAt;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: (json['_id'] ?? json['id']) as String,
      participants: (json['participants'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}