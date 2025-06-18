import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/private_message.dart';

class ChatService {
  final _chatCollection = FirebaseFirestore.instance.collection('chat');
  final _privateChatsCollection = FirebaseFirestore.instance.collection(
    'private_chats',
  );

  // 🔵 Chat global
  Future<void> sendMessage(ChatMessage message) async {
    await _chatCollection.add(message.toMap());
  }

  Stream<List<ChatMessage>> getMessagesStream() {
    return _chatCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()))
              .toList(),
        );
  }

  // 🟢 Chat privado
  Future<void> sendPrivateMessage({
    required String chatId,
    required PrivateMessage message,
  }) async {
    await _privateChatsCollection
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<PrivateMessage>> getPrivateMessages(String chatId) {
    return _privateChatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PrivateMessage.fromMap(doc.data()))
              .toList(),
        );
  }
}
