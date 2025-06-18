import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String _generateChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Usuarios Disponibles")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.where(
            (doc) => doc.id != currentUserId,
          );

          if (users.isEmpty) {
            return const Center(child: Text("No hay otros usuarios."));
          }

          return ListView(
            children: users.map((doc) {
              final userId = doc.id;
              final userName = doc['nombres'] ?? 'Usuario sin nombre';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(userName),
                subtitle: Text(userId),
                onTap: () {
                  final chatId = _generateChatId(currentUserId, userId);
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'chatId': chatId,
                      'receiverId': userId,
                      'receiverName': userName,
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
