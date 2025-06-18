import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  PrivateMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory PrivateMessage.fromMap(Map<String, dynamic> map) {
    return PrivateMessage(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
