import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_service.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart'; // WICHTIG für das einheitliche Design
import 'private_chat_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String search = "";

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
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    
    // 🔥 PERSONALISIERTE FARBE (wie im restlichen Design)
    final accentColor = ChatTheme.myBubbleColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Teilnehmer suchen", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // --- SUCHE (Design wie im PeopleScreen) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  search = v.trim().toLowerCase();
                }),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Suchen...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontWeight: FontWeight.w500
                  ),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- USER LISTE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((u) {
                  final uid = u.id;
                  final name = u['fullName'].toString().toLowerCase();
                  // Aktuellen User ausblenden & nach Suche filtern
                  return uid != currentUid && (search.isEmpty || name.contains(search));
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "Keine Teilnehmer gefunden",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final user = filtered[i];
                    final fullName = user['fullName'] ?? "Unbekannt";
                    final uid = user.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03), 
                            blurRadius: 10, 
                            offset: const Offset(0, 3)
                          )
                        ]
                      ),
                      child: ListTile(
                        onTap: () async {
                          final convId = await ChatService().createOrGetDirectChat(
                            currentUid: currentUid,
                            otherUid: uid,
                          );

                          if (!context.mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatScreen(
                                conversationId: convId,
                                title: fullName,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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