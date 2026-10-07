import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
  });

  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String status;

  factory MessageModel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final value = data['timestamp'];
    return MessageModel(
      id: document.id,
      senderId: data['senderId']?.toString() ?? '',
      senderEmail: data['senderEmail']?.toString() ?? '',
      receiverId: data['receiverId']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      timestamp: value is Timestamp ? value.toDate() : DateTime.now(),
      status: data['status']?.toString() ?? 'sent',
    );
  }

  factory MessageModel.pending({
    required String id,
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String message,
  }) => MessageModel(
    id: id,
    senderId: senderId,
    senderEmail: senderEmail,
    receiverId: receiverId,
    message: message,
    timestamp: DateTime.now(),
    status: 'sending',
  );
}
