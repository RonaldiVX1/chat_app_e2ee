import 'package:chat_app/app/data/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/chat_controller.dart';
import '../../../widgets/message_bubble.dart';
import '../../../widgets/message_input.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.receiver.username),
        centerTitle: false,
        actions: [
          // WebSocket connection indicator
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: controller.isConnected.value
              ? const Icon(Icons.wifi, color: Colors.green, size: 20)
              : const Icon(Icons.wifi_off, color: Colors.red, size: 20),
          )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (controller.chatRoomId.value != null) {
                controller.fetchMessagesByChatRoomId(setLoading: true);
              } else {
                controller.fetchMessages(setLoading: true);
              }
            },
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: SpinKitCircle(color: Colors.blue));
              }
              
              if (controller.messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[controller.messages.length - 1 - index];
                  final isCurrentUser = controller.isCurrentUser(message.senderId);
                  
                  return MessageBubble(
                    message: controller.getDecryptedContent(message),
                    time: _formatTime(message.createdAt),
                    isCurrentUser: isCurrentUser,
                    isEncrypted: !controller.decryptedMessages.containsKey(message.id), 
                    senderName: message.senderUsername ?? '',
                    status: _getMessageStatus(message),
                  );
                },
              );
            }),
          ),
          Obx(() => MessageInput(
            controller: controller.messageController,
            onSend: controller.sendMessage,
            isSending: controller.isSending.value,
            isEncrypted: true, 
          )),
        ],
      ),
    );
  }
  
  String _formatTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();
    
    if (dateTime.year == now.year && 
        dateTime.month == now.month && 
        dateTime.day == now.day) {
      // Today, show only time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Not today, show date and time
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  String _getMessageStatus(MessageModel message) {
    if (message.failed) return 'failed';
    if (message.pending) return 'pending';
    if (message.read) return 'read';
    if (message.delivered) return 'delivered';
    return 'sent';
  }
}