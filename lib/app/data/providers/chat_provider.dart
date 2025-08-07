import 'dart:convert';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_room_model.dart';
import 'api_provider.dart';

class ChatProvider {
  final ApiProvider _apiProvider = ApiProvider();

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _apiProvider.get('/users');
      
      if (response != null && response['users'] != null) {
        final List<dynamic> usersJson = response['users'];
        return usersJson.map((user) => UserModel.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      print('Get users error: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getMessages(String receiverId) async {
    try {
      final response = await _apiProvider.get('/api/messages/$receiverId');
      
      if (response != null && response['messages'] != null) {
        return (response['messages'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }
  
  Future<ChatRoomModel?> getChatRoom(String otherUserId) async {
    try {
      final data = {
        'otherUserId': otherUserId
      };
      
      final response = await _apiProvider.post('/api/chatroom', data);
      
      if (response != null && response['chatRoom'] != null) {
        return ChatRoomModel.fromJson(response['chatRoom']);
      }
      return null;
    } catch (e) {
      print('Get chat room error: $e');
      return null;
    }
  }
  
  Future<List<MessageModel>> getMessagesByChatRoomId(String chatRoomId) async {
    try {
      final response = await _apiProvider.get('/api/messages/$chatRoomId');
      
      if (response != null && response['messages'] != null) {
        return (response['messages'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get messages by chat room ID error: $e');
      return [];
    }
  }

  Future<MessageModel?> sendMessage(String receiverId, String content) async {
    try {
      final data = {
        'receiverId': receiverId,
        'content': content,
      };
      
      final response = await _apiProvider.post('/api/messages', data);
      
      if (response != null && response['message'] != null) {
        return MessageModel.fromJson(response['message']);
      }
      return null;
    } catch (e) {
      print('Send message error: $e');
      return null;
    }
  }
  
  Future<MessageModel?> sendMessageToChatRoom(String chatRoomId, String content) async {
    try {
      final data = {
        'chatRoomId': chatRoomId,
        'content': content,
      };
      
      final response = await _apiProvider.post('/messages', data);
      
      if (response != null && response['message'] != null) {
        return MessageModel.fromJson(response['message']);
      }
      return null;
    } catch (e) {
      print('Send message to chat room error: $e');
      return null;
    }
  }
}