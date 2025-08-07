import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:web_socket_channel/io.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/chat_room_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../utils/crypto_util.dart';
import '../../../data/providers/user_storage.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../data/providers/api_provider.dart';

class ChatController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final UserStorage _userStorage = UserStorage();

  final messageController = TextEditingController();
  final messages = <MessageModel>[].obs;
  final decryptedMessages = <String, String>{}.obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final currentUser = Rxn<UserModel>();
  final isConnected = false.obs;

  late UserModel receiver;
  Timer? _messageTimer;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  EcdhPrivateKey? _privateKey;

  final chatRoom = Rxn<ChatRoomModel>();
  final chatRoomId = RxnString();

  @override
  void onInit() {
    super.onInit();
    receiver = Get.arguments as UserModel;
    _loadCurrentUser();
    _loadPrivateKey();
    initChatRoom();
  }

  @override
  void onClose() {
    messageController.dispose();
    if (_messageTimer != null) {
      _messageTimer!.cancel();
    }
    _disconnectWebSocket();
    super.onClose();
  }

  void _disconnectWebSocket() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    isConnected.value = false;
    print('WebSocket disconnected');
  }

  Future<void> initChatRoom() async {
    isLoading.value = true;
    try {
      final result = await _chatRepository.getChatRoom(receiver.id);
      if (result != null) {
        chatRoom.value = result;
        chatRoomId.value = result.id;
        print("${chatRoomId.value} chatroom IDD");
        await fetchMessagesByChatRoomId(setLoading: false);
        // Connect to WebSocket after loading messages
        _connectWebSocket();
      } else {
        // Fallback to old method if chat room not found
        await fetchMessages(setLoading: false);
      }
    } catch (e) {
      print('Error initializing chat room: $e');
      // Fallback to old method if chat room initialization fails
      await fetchMessages(setLoading: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _connectWebSocket() async {
    if (chatRoomId.value == null || isConnected.value) return;

    try {
      final token = await _userStorage.getToken();
      if (token == null) {
        print('Cannot connect to WebSocket: Token not found');
        return;
      }

      final wsUrl = 'ws://10.247.215.236:8081/ws/chatroom/${chatRoomId.value}';
      print('Connecting to WebSocket: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      _subscription = _channel!.stream.listen(
        (dynamic message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          isConnected.value = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          isConnected.value = false;
          
          // Mark any messages that were marked as delivered but not confirmed by server as pending
          _markMessagesAsPendingOnDisconnect();
          
          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (!isConnected.value) {
              _connectWebSocket();
            }
          });
        },
      );

      isConnected.value = true;
      print('WebSocket connected successfully');

      // Cancel the polling timer if WebSocket is connected
      if (_messageTimer != null) {
        _messageTimer!.cancel();
        _messageTimer = null;
      }
      
      // Send any pending messages when WebSocket reconnects
      _sendPendingMessages();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      isConnected.value = false;

      // Fallback to polling if WebSocket connection fails
      if (_messageTimer == null) {
        _messageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (chatRoomId.value != null) {
            fetchMessagesByChatRoomId(setLoading: false);
          } else {
            _fetchMessagesQuietly();
          }
        });
      }
    }
  }

  Future<void> fetchMessages({bool setLoading = true}) async {
    if (setLoading) isLoading.value = true;
    try {
      final messagesList = await _chatRepository.getMessages(receiver.id);
      messages.value = messagesList;
      _decryptMessages();
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      if (setLoading) isLoading.value = false;
    }
  }

  // Fetch messages without showing loading indicator
  Future<void> _fetchMessagesQuietly() async {
    try {
      final messagesList = await _chatRepository.getMessages(receiver.id);
      messages.value = messagesList;
      _decryptMessages();
    } catch (e) {
      print('Error fetching messages quietly: $e');
    }
  }

  Future<void> fetchMessagesByChatRoomId({bool setLoading = true}) async {
    if (chatRoomId.value == null) return;

    if (setLoading) isLoading.value = true;
    try {
      final messagesList = await _chatRepository.getMessagesByChatRoomId(
        chatRoomId.value!,
      );
      messages.value = messagesList;
      _decryptMessages();
    } catch (e) {
      print('Error fetching messages by chat room ID: $e');
    } finally {
      if (setLoading) isLoading.value = false;
    }
  }

  // Metode untuk mendekripsi pesan menggunakan private key pengguna saat ini dan public key pengirim
  Future<void> _decryptMessages() async {
    if (_privateKey == null || currentUser.value == null) return;

    for (final message in messages) {
      // Jika pesan sudah didekripsi, lewati
      if (decryptedMessages.containsKey(message.id)) continue;

      try {
        // Tentukan public key yang akan digunakan berdasarkan pengirim pesan
        String publicKeyString;
        if (isCurrentUser(message.senderId)) {
          // Jika pengirim adalah pengguna saat ini, gunakan public key penerima
          publicKeyString = receiver.publicKey;
        } else {
          // Jika pengirim adalah orang lain, gunakan public key pengirim (receiver)
          publicKeyString = receiver.publicKey;
        }

        // Import public key
        final publicKey = await CryptoUtil.importPublicKey(publicKeyString);
        if (publicKey == null) {
          print('Failed to import public key for message ${message.id}');
          continue;
        }

        // Derive shared secret
        final sharedSecret = await CryptoUtil.deriveSharedSecret(
          _privateKey!,
          publicKey,
        );
        if (sharedSecret == null) {
          print('Failed to derive shared secret for message ${message.id}');
          continue;
        }

        // Decrypt message
        final decryptedContent = await CryptoUtil.decryptMessage(
          message.content,
          sharedSecret,
        );
        if (decryptedContent != null) {
          decryptedMessages[message.id] = decryptedContent;
          print('Successfully decrypted message ${message.id}');
        } else {
          print('Failed to decrypt message ${message.id}');
        }
      } catch (e) {
        print('Error decrypting message ${message.id}: $e');
      }
    }
  }

  Future<String?> _encryptMessage(String text) async {
    if (_privateKey == null) {
      print('Private key not found, cannot encrypt message');
      return null;
    }

    try {
      // Import receiver's public key
      final publicKey = await CryptoUtil.importPublicKey(receiver.publicKey);
      if (publicKey == null) {
        print('Failed to import receiver public key');
        return null;
      }

      // Derive shared secret
      final sharedSecret = await CryptoUtil.deriveSharedSecret(
        _privateKey!,
        publicKey,
      );
      if (sharedSecret == null) {
        print('Failed to derive shared secret');
        return null;
      }

      // Encrypt message
      final encryptedContent = await CryptoUtil.encryptMessage(
        text,
        sharedSecret,
      );
      if (encryptedContent == null) {
        print('Failed to encrypt message');
        return null;
      }

      return encryptedContent;
    } catch (e) {
      print('Error encrypting message: $e');
      return null;
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      print('Received WebSocket message: $data');

      if (data['type'] == 'message') {
        // Handle new message
        final newMessage = MessageModel.fromJson(data['message']);

        final exists = messages.any((m) => m.id == newMessage.id);

        final isFromCurrentUser = isCurrentUser(data['message']['from'] ?? data['message']['senderId'] ?? '');

        if (!exists && !isFromCurrentUser) {
          messages.add(newMessage);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          _decryptMessage(newMessage);
        } else if (isFromCurrentUser) {
          _updateTempMessageStatus(data['message']);
        }
      } else if (data['type'] == 'message_status') {
        // Handle status updates (read, delivered, etc.)
        final messageId = data['messageId'];
        final status = data['status'];

        print("Received message status update: $status for message $messageId");


        int index = messages.indexWhere((m) => m.id == messageId);

        if (index == -1 && currentUser.value != null) {
          index = messages.lastIndexWhere((m) => 
            m.id.startsWith('temp_') && 
            m.senderId == currentUser.value!.id);
        }
        
        if (index != -1) {
          final message = messages[index];
          final updatedMessage = MessageModel(
            id: message.id,
            senderId: message.senderId,
            senderUsername: message.senderUsername,
            receiverId: message.receiverId,
            chatRoom: message.chatRoom,
            content: message.content,
            delivered: status == 'delivered' ? true : message.delivered,
            read: status == 'read' ? true : message.read,
            pending: false,
            failed: false,
            deliveredAt: status == 'delivered'
                ? DateTime.now().toIso8601String()
                : message.deliveredAt,
            readAt: status == 'read'
                ? DateTime.now().toIso8601String()
                : message.readAt,
            createdAt: message.createdAt,
            to: message.to,
            type: message.type,
          );

          messages[index] = updatedMessage;
          
          messages.refresh();
          
          print("Updated message status: ${messages[index].id} - delivered: ${messages[index].delivered}, read: ${messages[index].read}");
        } else {
          print("Message not found for status update: $messageId");
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  Future<void> _decryptMessage(MessageModel message) async {
    if (_privateKey == null ||
        currentUser.value == null ||
        decryptedMessages.containsKey(message.id))
      return;

    try {
      String publicKeyString;
      if (isCurrentUser(message.senderId)) {
        publicKeyString = receiver.publicKey;
      } else {
        publicKeyString = receiver.publicKey;
      }

      final publicKey = await CryptoUtil.importPublicKey(publicKeyString);
      if (publicKey == null) {
        print('Failed to import public key for message ${message.id}');
        return;
      }

      final sharedSecret = await CryptoUtil.deriveSharedSecret(
        _privateKey!,
        publicKey,
      );
      if (sharedSecret == null) {
        print('Failed to derive shared secret for message ${message.id}');
        return;
      }

      final decryptedContent = await CryptoUtil.decryptMessage(
        message.content,
        sharedSecret,
      );
      if (decryptedContent != null) {
        decryptedMessages[message.id] = decryptedContent;
        print('Successfully decrypted message ${message.id}');
      } else {
        print('Failed to decrypt message ${message.id}');
      }
    } catch (e) {
      print('Error decrypting message ${message.id}: $e');
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSending.value = true;
    try {
      // Encrypt message before sending
      final encryptedText = await _encryptMessage(text);
      if (encryptedText == null) {
        Fluttertoast.showToast(msg: 'Failed to encrypt message');
        return;
      }

      // Check if WebSocket is connected and chatRoomId is available
      if (isConnected.value && chatRoomId.value != null && _channel != null) {
        // Send message via WebSocket with additional metadata
        final timestamp = DateTime.now().toIso8601String();
        final messageData = {
          'type': 'message',
          'chatRoomId': chatRoomId.value,
          'to': receiver.id,
          'from': currentUser.value!.id,
          'content': encryptedText,
          'timestamp': timestamp,
          'senderUsername': currentUser.value!.username,
          'status': 'delivered', // Mark as delivered immediately
        };

        // Add message to UI with delivered status since WebSocket is connected
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempMessage = MessageModel(
          type: 'message',
          id: tempId,
          senderId: currentUser.value!.id,
          senderUsername: currentUser.value!.username,
          to: receiver.id,
          chatRoom: chatRoomId.value,
          content: encryptedText,
          pending: false,
          delivered: true,
          read: false,
          createdAt: DateTime.now().toIso8601String(),
        );

        messages.add(tempMessage);
        decryptedMessages[tempId] = text;
        messageController.clear();

        _channel!.sink.add(jsonEncode(messageData));
      } else {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempMessage = MessageModel(
          type: 'message',
          id: tempId,
          senderId: currentUser.value!.id,
          senderUsername: currentUser.value!.username,
          to: receiver.id,
          chatRoom: chatRoomId.value,
          content: encryptedText,
          pending: true,  // Mark as pending since WebSocket is not connected
          delivered: false,
          read: false,
          createdAt: DateTime.now().toIso8601String(),
        );

        messages.add(tempMessage);
        decryptedMessages[tempId] = text;
        messageController.clear();
        
        _storePendingMessage(tempId, {
          'type': 'message',
          'chatRoomId': chatRoomId.value,
          'to': receiver.id,
          'from': currentUser.value!.id,
          'content': encryptedText,
          'timestamp': DateTime.now().toIso8601String(),
          'senderUsername': currentUser.value!.username,
          'status': 'pending',
        });
        
        Fluttertoast.showToast(msg: 'Message will be sent when connection is restored');
        
        if (!isConnected.value) {
          _connectWebSocket();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sending message: ${e.toString()}');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userStorage.getUser();
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadPrivateKey() async {
    try {
      _privateKey = await CryptoUtil.getPrivateKey();
      if (_privateKey == null) {
        print('Private key not found');
      }
    } catch (e) {
      print('Error loading private key: $e');
    }
  }

  bool isCurrentUser(String senderId) {
    return senderId == currentUser.value?.id;
  }

  String getDecryptedContent(MessageModel message) {
    return decryptedMessages[message.id] ?? message.content;
  }
  
  // Map to store pending messages that need to be sent when WebSocket reconnects
  final Map<String, Map<String, dynamic>> _pendingMessages = {};
  
  void _storePendingMessage(String tempId, Map<String, dynamic> messageData) {
    _pendingMessages[tempId] = messageData;
    print('Stored pending message with temp ID: $tempId');
  }
  
  void _markMessagesAsPendingOnDisconnect() {

    final messagesToUpdate = <int>[];
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.id.startsWith('temp_') && 
          message.senderId == currentUser.value?.id && 
          message.delivered && 
          !message.pending) {
        messagesToUpdate.add(i);
        
        // Make sure the message is in the pending messages map
        if (!_pendingMessages.containsKey(message.id)) {
          _storePendingMessage(message.id, {
            'type': 'message',
            'chatRoomId': message.chatRoom,
            'to': message.to,
            'from': message.senderId,
            'content': message.content,
            'timestamp': message.createdAt,
            'senderUsername': message.senderUsername,
            'status': 'pending',
          });
        }
      }
    }
    
    // Update the messages to pending status
    for (final index in messagesToUpdate) {
      final message = messages[index];
      final updatedMessage = MessageModel(
        id: message.id,
        senderId: message.senderId,
        senderUsername: message.senderUsername,
        receiverId: message.receiverId,
        chatRoom: message.chatRoom,
        content: message.content,
        pending: true,  // Mark as pending since WebSocket is disconnected
        delivered: false,
        read: false,
        createdAt: message.createdAt,
        to: message.to,
        type: message.type,
      );
      
      messages[index] = updatedMessage;
    }
    
    if (messagesToUpdate.isNotEmpty) {
      print('Marked ${messagesToUpdate.length} messages as pending due to WebSocket disconnect');
      messages.refresh();
    }
  }
  
  void _sendPendingMessages() {
    if (_pendingMessages.isEmpty || _channel == null || !isConnected.value) {
      return;
    }
    
    print('Sending ${_pendingMessages.length} pending messages...');
    
    // Create a copy of the keys to avoid concurrent modification
    final pendingIds = _pendingMessages.keys.toList();
    
    for (final tempId in pendingIds) {
      final messageData = _pendingMessages[tempId];
      if (messageData != null) {
        messageData['status'] = 'delivered';
        
        // Send via WebSocket
        _channel!.sink.add(jsonEncode(messageData));
        
        // Update UI message status
        final index = messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          final message = messages[index];
          final updatedMessage = MessageModel(
            id: tempId,
            senderId: message.senderId,
            senderUsername: message.senderUsername,
            receiverId: message.receiverId,
            chatRoom: message.chatRoom,
            content: message.content,
            pending: false,
            delivered: true,
            read: false,
            createdAt: message.createdAt,
            to: message.to,
            type: message.type,
          );
          
          messages[index] = updatedMessage;
        }
        
        // Remove from pending messages
        _pendingMessages.remove(tempId);
        
        print('Sent pending message with temp ID: $tempId');
      }
    }
    
    // Force UI update
    messages.refresh();
  }
  
  void _updateTempMessageStatus(Map<String, dynamic> messageData) {
    // Get the server-generated message ID
    final String messageId = messageData['_id'] ?? messageData['id'] ?? '';
    if (messageId.isEmpty) return;
    

    final tempIndex = messages.lastIndexWhere((m) => 
      m.id.startsWith('temp_') && 
      m.senderId == currentUser.value!.id);
      
    if (tempIndex != -1) {
      final tempMessage = messages[tempIndex];
      final confirmedMessage = MessageModel(
        id: messageId,
        senderId: tempMessage.senderId,
        senderUsername: tempMessage.senderUsername,
        receiverId: tempMessage.receiverId,
        chatRoom: tempMessage.chatRoom,
        content: tempMessage.content,
        pending: false,
        delivered: true,
        read: false,
        createdAt: messageData['createdAt'] ?? tempMessage.createdAt,
        to: tempMessage.to,
        type: tempMessage.type,
      );
      
  
      messages[tempIndex] = confirmedMessage;
      
    
      if (decryptedMessages.containsKey(tempMessage.id)) {
        final decryptedContent = decryptedMessages[tempMessage.id];
        decryptedMessages[messageId] = decryptedContent!;
        decryptedMessages.remove(tempMessage.id);
      }
      
     
      _pendingMessages.remove(tempMessage.id);
      
      print('Updated temporary message with server message: $messageId');
    }
  }
}
