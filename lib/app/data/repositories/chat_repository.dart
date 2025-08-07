import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_room_model.dart';
import '../providers/chat_provider.dart';

class ChatRepository {
  final ChatProvider _chatProvider = ChatProvider();

  Future<List<UserModel>> getUsers() {
    return _chatProvider.getUsers();
  }

  Future<List<MessageModel>> getMessages(String receiverId) {
    return _chatProvider.getMessages(receiverId);
  }

  Future<MessageModel?> sendMessage(String receiverId, String content) {
    return _chatProvider.sendMessage(receiverId, content);
  }
  
  Future<ChatRoomModel?> getChatRoom(String otherUserId) {
    return _chatProvider.getChatRoom(otherUserId);
  }
  
  Future<List<MessageModel>> getMessagesByChatRoomId(String chatRoomId) {
    return _chatProvider.getMessagesByChatRoomId(chatRoomId);
  }
  
  Future<MessageModel?> sendMessageToChatRoom(String chatRoomId, String content) {
    return _chatProvider.sendMessageToChatRoom(chatRoomId, content);
  }
}