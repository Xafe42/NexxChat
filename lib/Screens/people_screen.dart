import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_service.dart';
import 'private_chat_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Text(
                  "People",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // SUCHE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v.trim().toLowerCase();
                }),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Search people...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // USER LISTE (Kontakte)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter: Nicht man selbst + Suchbegriff
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final name = (data['fullName'] ?? '').toString().toLowerCase();
                  
                  if (uid == currentUid) return false;
                  if (_search.isNotEmpty && !name.contains(_search)) return false;
                  
                  return true;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final fullName = userData['fullName'] ?? "Unknown";
                    // Hier könnte man auch ein Profilbild laden, falls vorhanden

                    return InkWell(
                      onTap: () async {
                         // Erstelle oder hole Chat ID
                         final chatService = ChatService();
                         final convId = await chatService.createOrGetDirectChat(
                           currentUid: currentUid, 
                           otherUid: userDoc.id
                         );
                         
                         // Navigiere zum Chat
                         Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => PrivateChatScreen(
                             conversationId: convId,
                             title: fullName,
                           ))
                         );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueAccent.withOpacity(0.2),
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(Icons.message_rounded, color: Colors.grey[400]),
                          ],
                        ),
                      ),
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