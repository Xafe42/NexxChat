import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_theme.dart'; // WICHTIG
import 'private_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _groupNameCtrl = TextEditingController();
  final Set<String> _selectedUids = {}; 
  
  bool _isCreating = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if(mounted) setState(() {});
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    FocusScope.of(context).unfocus();
    final groupName = _groupNameCtrl.text.trim();
    
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte gib einen Gruppennamen ein!"), backgroundColor: Colors.red));
      return;
    }
    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wähle mindestens einen Teilnehmer aus!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUid = _auth.currentUser!.uid;
      final members = [currentUid, ..._selectedUids];

      final ref = await _firestore.collection('conversations').add({
        'name': groupName,
        'isGroup': true,
        'admin': currentUid,
        'members': members,
        'lastMessage': 'Gruppe erstellt',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser!.email,
        'icon': null,
        'color': ChatTheme.myBubbleColor.value, // 🔥 Speichert die aktuelle Theme Farbe für die Gruppe
        'typingUsers': [], 
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(conversationId: ref.id, title: groupName)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    // 🔥 PERSONALISIERTE FARBE
    final accentColor = ChatTheme.myBubbleColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Neue Gruppe", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // 🔥 Personalisiert
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
                child: _isCreating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Erstellen", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1), // 🔥 Personalisiert
                    shape: BoxShape.circle
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: accentColor, size: 30), // 🔥 Personalisiert
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _groupNameCtrl,
                    onChanged: (v) => setState(() {}), 
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Gruppenname",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  hintText: "Teilnehmer suchen...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15)
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final name = (data['fullName'] ?? '').toString().toLowerCase();
                  if (uid == currentUid) return false;
                  if (_search.isNotEmpty && !name.contains(_search)) return false;
                  return true;
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Keine User gefunden"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final fullName = userData['fullName'] ?? "Unbekannt";
                    final uid = userDoc.id;
                    final isSelected = _selectedUids.contains(uid);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) _selectedUids.remove(uid);
                          else _selectedUids.add(uid);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: accentColor, // 🔥 Personalisiert
                                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(width: 15),
                            
                            Expanded(
                              child: Text(
                                fullName,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16
                                ),
                              ),
                            ),

                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? accentColor : Colors.grey[400]!, // 🔥 Personalisiert
                                  width: 2
                                ),
                                color: isSelected ? accentColor : Colors.transparent // 🔥 Personalisiert
                              ),
                              child: isSelected 
                                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                : null,
                            )
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