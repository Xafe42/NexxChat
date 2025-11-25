

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/services/chat_service.dart';
import 'private_chat_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _auth = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();
  String search = "";

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Chat"),
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((u) {
                  final name = u['fullName'].toString().toLowerCase();
                  return search.isEmpty || name.contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final user = filtered[i];
                    final uid = user.id;

                    if (uid == currentUid) return const SizedBox();

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['fullName'][0].toUpperCase()),
                      ),
                      title: Text(user['fullName']),
                      onTap: () async {
                       
                        final convId = await ChatService().createOrGetDirectChat(
                          currentUid: currentUid,
                          otherUid: uid,
                        );

                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatScreen(
                              conversationId: convId,
                              title: user['fullName'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}