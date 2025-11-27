import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  // 🔥 Logik zum Erstellen der Gruppe
  Future<void> _createGroup() async {
    // 1. Tastatur schließen
    FocusScope.of(context).unfocus();

    final groupName = _groupNameCtrl.text.trim();
    
    // 2. VALIDIERUNG: Prüfen ob alles da ist und Feedback geben
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte gib einen Gruppennamen ein!"),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wähle mindestens einen Teilnehmer aus!"),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUid = _auth.currentUser!.uid;
      
      // Teilnehmerliste erstellen (Du + die Ausgewählten)
      final members = [currentUid, ..._selectedUids];

      print("Erstelle Gruppe '$groupName' mit ${members.length} Mitgliedern.");

      // 3. Gruppe in Firestore speichern
      final ref = await _firestore.collection('conversations').add({
        'name': groupName,
        'isGroup': true,
        'admin': currentUid,
        'members': members,
        'lastMessage': 'Gruppe erstellt',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser!.email,
        'icon': null,
        'color': Colors.blue.value,
        'typingUsers': [], 
      });

      print("Gruppe erstellt mit ID: ${ref.id}");

      // 4. Zum Chat navigieren
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PrivateChatScreen(
              conversationId: ref.id,
              title: groupName,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ FEHLER: $e");
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Neue Gruppe"),
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFF075E54),
        actions: [
          // ERSTELLEN BUTTON (Immer klickbar für Feedback)
          TextButton(
            onPressed: _isCreating ? null : _createGroup, 
            child: _isCreating 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  "Erstellen",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Gruppenname Eingabe
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.groups, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Gruppenname eingeben",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 2. Suche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Teilnehmer suchen...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
            ),
          ),

          // 3. User Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filterung
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final name = (data['fullName'] ?? '').toString().toLowerCase();
                  
                  if (uid == currentUid) return false; // Nicht sich selbst anzeigen
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

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: const Color(0xFF075E54),
                      title: Text(
                        fullName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black54),
                        ),
                      ),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedUids.add(uid);
                          } else {
                            _selectedUids.remove(uid);
                          }
                        });
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