import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_service.dart';
import '../core/services/chat_theme.dart'; // WICHTIG
import 'create_group_screen.dart';
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
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    // 🔥 PERSONALISIERTE FARBE
    final accentColor = ChatTheme.myBubbleColor;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
            child: Row(
              children: [
                Text(
                  "People",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // SUCHE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v.trim().toLowerCase();
                }),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Suchen...",
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: accentColor));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final name =
                      (data['fullName'] ?? '').toString().toLowerCase();

                  if (uid == currentUid) return false;
                  if (_search.isNotEmpty && !name.contains(_search))
                    return false;

                  return true;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: users.length + 1,
                  itemBuilder: (context, index) {
                    // --- NEUE GRUPPE BUTTON ---
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateGroupScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      accentColor.withValues(alpha: 0.8),
                                      accentColor
                                    ], // 🔥 Personalisiert
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6))
                                ]),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_add_rounded,
                                    color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  "Neue Gruppe erstellen",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final userDoc = users[index - 1];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final fullName = userData['fullName'] ?? "Unknown";
                    final photoUrl = (userData['photoURL'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]),
                      child: ListTile(
                        onTap: () async {
                          final chatService = ChatService();
                          final convId =
                              await chatService.createOrGetDirectChat(
                                  currentUid: currentUid, otherUid: userDoc.id);

                          // FIX: Prüfung auf 'context.mounted' nach einem asynchronen Aufruf (await)
                          if (!context.mounted) return;

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PrivateChatScreen(
                                        conversationId: convId,
                                        title: fullName,
                                      )));
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: accentColor), // 🔥 Personalisiert
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
