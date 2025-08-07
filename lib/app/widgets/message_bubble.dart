import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isCurrentUser;
  final bool isEncrypted;
  final String senderName;
  final String status;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.time,
    required this.isCurrentUser,
    this.isEncrypted = true,
    this.senderName = '',
    this.status = 'sent',
  }) : super(key: key);

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;
    
    switch (status) {
      case 'sent':
        iconData = Icons.check;
        iconColor = Colors.white.withOpacity(0.7);
        break;
      case 'delivered':
        iconData = Icons.done_all;
        iconColor = Colors.white.withOpacity(0.7);
        break;
      case 'read':
        iconData = Icons.done_all;
        iconColor = Colors.blue.shade300;
        break;
      case 'pending':
        iconData = Icons.access_time;
        iconColor = Colors.white.withOpacity(0.7);
        break;
      case 'failed':
        iconData = Icons.error_outline;
        iconColor = Colors.red.shade300;
        break;
      default:
        iconData = Icons.check;
        iconColor = Colors.white.withOpacity(0.7);
    }
    
    return Icon(
      iconData,
      size: 12,
      color: iconColor,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            if (!isCurrentUser && senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  senderName,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isCurrentUser 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                if (isEncrypted) ...[  
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: isCurrentUser 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.7),
                  ),
                ],
                if (isCurrentUser) ...[  
                  const SizedBox(width: 4),
                  _buildStatusIcon(status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}