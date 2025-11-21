// lib/core/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  pending('PENDING'),
  sent('SENT'),
  delivered('DELIVERED'),
  seen('SEEN');

  final String value;
  const MessageStatus(this.value);

  factory MessageStatus.fromValue(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final Timestamp? timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.status,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
      status: data['status'] != null
          ? MessageStatus.fromValue(data['status'])
          : MessageStatus.sent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      'status': status.value,
    };
  }
}