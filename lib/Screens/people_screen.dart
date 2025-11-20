import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// === NEW ===
import 'package:nexxchat_firebase/core/services/chat_service.dart';
import 'package:nexxchat_firebase/Screens/private_chat_screen.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser!.email;
    final currentUid = currentUser.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No users found", style: TextStyle(fontSize: 18)),
            );
          }

          // Filter users: hide current user
          final users = snapshot.data!.docs.where((doc) {
            return doc["email"] != currentEmail;
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text("No other users available",
                  style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final String name = doc["fullName"] ?? "Unknown";
              final String email = doc["email"] ?? "";
              final String pic = doc["profilePic"] ?? "";
              final String otherUid = doc["uid"];

              return InkWell(
                onTap: () async {
                  final chatService = ChatService();

                  // create or get conversation
                  final convId = await chatService.createOrGetDirectChat(
                    currentUid: currentUid,
                    otherUid: otherUid,
                  );

                  if (!context.mounted) return;

                  // open chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivateChatScreen(
                        conversationId: convId,
                        title: name,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),

                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        backgroundImage:
                            pic.isNotEmpty ? NetworkImage(pic) : null,
                        child: pic.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "?",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}