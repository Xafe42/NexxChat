import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nexxchat_firebase/Screens/call_screen.dart';
import 'package:nexxchat_firebase/Screens/image_bot_screen.dart';
import 'package:path/path.dart' as path;

// Mini-apps & previews
import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../core/services/chat_service.dart';
import '../core/services/chat_theme.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_preview.dart';
import '../widgets/hello_preview.dart';
import '../widgets/reaction_picker.dart';

class PrivateChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _chatService = ChatService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  User? _user;
  bool _sending = false;
  bool _lastTypingState = false;
  bool _showScrollBtn = false;

  // -------- Mini-apps state --------
  String _raw = "";
  ChatCommand? _aktiveCmd;
  bool _isAiPreviewVisible = false;
  bool _isSlashToolbarVisible = false;
  String? otherUserId;
  bool userDeleted = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadTheme();
    _loadOtherUser();

    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;

      final show = _scrollCtrl.offset > 300;
      if (show != _showScrollBtn) {
        setState(() => _showScrollBtn = show);
      }
    });
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _setTyping(false);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Funktion für Gruppen Einstellungen
  void _showGroupSettings(BuildContext context, Map<String, dynamic> convData) {
    final currentUid = _auth.currentUser?.uid;
    final adminUid = convData['admin'];
    final isGroup = convData['isGroup'] == true;
    final members = List<String>.from(convData['members'] ?? []);

    if (!isGroup) return;

    showModalBottomSheet(
<<<<<<< Updated upstream
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Damit es nicht unter die Statusbar rutscht
      builder: (context) {
        final nameCtrl = TextEditingController(text: convData['name']);
        
        return DraggableScrollableSheet( // Macht das Sheet größer/scrollbar
          expand: false,
          initialChildSize: 0.9, // 90% der Höhe
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, 
                right: 20, 
                top: 20
              ),
              child: ListView( // ListView statt Column für Scrollen
                controller: scrollController,
                children: [
                  const Text("Gruppen Einstellungen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  
                  // --- 1. NAME ÄNDERN ---
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Gruppenname",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isNotEmpty) {
                            await _db.collection('conversations').doc(widget.conversationId).update({
                              'name': nameCtrl.text.trim()
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name gespeichert!")));
                          }
                        },
                      )
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 2. TEILNEHMER LISTE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Teilnehmer (${members.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      // Hinzufügen Button
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.blue),
                        onPressed: () => _showAddMemberDialog(context, members),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // StreamBuilder für die User-Details der Mitglieder
                  StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('users').where(FieldPath.documentId, whereIn: members).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final userDocs = snapshot.data!.docs;
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userDocs.length,
                        itemBuilder: (context, index) {
                          final userData = userDocs[index].data() as Map<String, dynamic>;
                          final uid = userDocs[index].id;
                          final name = userData['fullName'] ?? "Unbekannt";
                          final isAdmin = uid == adminUid;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
                            ),
                            title: Text(name + (uid == currentUid ? " (Du)" : "")),
                            subtitle: isAdmin ? const Text("Admin", style: TextStyle(color: Colors.green, fontSize: 12)) : null,
                            trailing: (currentUid == adminUid && uid != currentUid)
                                ? IconButton( // Admin kann andere kicken
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _removeMember(uid, name),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  
                  // --- 3. AKTIONEN (Verlassen / Löschen) ---
                  
                  // Gruppe verlassen
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                    title: const Text("Gruppe verlassen", style: TextStyle(color: Colors.orange)),
                    onTap: () => _leaveGroup(currentUid!, members),
                  ),

                  // Löschen (Nur Admin)
                  if (currentUid == adminUid)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("Gruppe löschen", style: TextStyle(color: Colors.red)),
                      onTap: () => _deleteGroup(context),
                    ),
                    
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- HELPER: Dialog zum Hinzufügen von Mitgliedern ---
  void _showAddMemberDialog(BuildContext context, List<String> currentMembers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Teilnehmer hinzufügen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // Zeige alle User, die NOCH NICHT in der Gruppe sind
                    // (Firestore 'not-in' ist limitiert, besser client-side filtern oder einfache Query)
                    stream: _db.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      // Filtere User, die schon drin sind
                      final availableUsers = snapshot.data!.docs.where((doc) => !currentMembers.contains(doc.id)).toList();

                      if (availableUsers.isEmpty) {
                        return const Center(child: Text("Keine weiteren Nutzer gefunden"));
                      }

                      return ListView.builder(
                        controller: scrollCtrl,
                        itemCount: availableUsers.length,
                        itemBuilder: (context, index) {
                          final userDoc = availableUsers[index];
                          final userData = userDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(child: Text((userData['fullName'] ?? "?")[0])),
                            title: Text(userData['fullName'] ?? "Unbekannt"),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () async {
                                // User hinzufügen
                                await _db.collection('conversations').doc(widget.conversationId).update({
                                  'members': FieldValue.arrayUnion([userDoc.id])
                                });
                                if (mounted) {
                                  Navigator.pop(context); // Dialog schließen
                                  // Optional: Toast/Snackbar
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- HELPER: Mitglied entfernen ---
  Future<void> _removeMember(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("$name entfernen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Nein")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Ja", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('conversations').doc(widget.conversationId).update({
        'members': FieldValue.arrayRemove([uid])
      });
    }
  }

  // --- HELPER: Gruppe verlassen ---
  Future<void> _leaveGroup(String myUid, List<String> members) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Gruppe verlassen?"),
        content: const Text("Du kannst danach keine Nachrichten mehr senden."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Abbrechen")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Verlassen", style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm == true) {
      // Wenn ich der letzte bin, Gruppe löschen? Oder einfach raus.
      if (members.length <= 1) {
         // Letzte Person -> Löschen
         await _db.collection('conversations').doc(widget.conversationId).delete();
      } else {
         // Einfach raus
         await _db.collection('conversations').doc(widget.conversationId).update({
          'members': FieldValue.arrayRemove([myUid])
        });
      }
      if (mounted) {
        Navigator.pop(context); // Menü zu
        Navigator.pop(context); // Chat Screen zu (zurück zur Home)
      }
    }
  }

  // --- HELPER: Gruppe löschen (Admin) ---
  Future<void> _deleteGroup(BuildContext context) async {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Gruppe löschen?"),
      content: const Text("Dies kann nicht rückgängig gemacht werden."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Abbrechen")),
        TextButton(onPressed: () async {
           Navigator.pop(c); // Dialog zu
           Navigator.pop(context); // BottomSheet zu
           Navigator.pop(context); // Screen zu
           await _db.collection('conversations').doc(widget.conversationId).delete();
        }, child: const Text("Löschen", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
    // ---------- Sart Video Call----------
=======
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final nameCtrl = TextEditingController(text: convData['name']);

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Gruppen Einstellungen",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Name ändern
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Gruppenname"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      await _db
                          .collection('conversations')
                          .doc(widget.conversationId)
                          .update({'name': nameCtrl.text.trim()});
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text("Speichern"),
                ),

                const SizedBox(height: 20),

                // Löschen (Nur wenn Admin)
                if (currentUid == adminUid)
                  TextButton.icon(
                    onPressed: () async {
                      // Sicherheitsabfrage
                      showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                                title: const Text("Gruppe löschen?"),
                                content: const Text(
                                    "Dies kann nicht rückgängig gemacht werden."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text("Abbrechen")),
                                  TextButton(
                                      onPressed: () async {
                                        Navigator.pop(c); // Dialog zu
                                        Navigator.pop(
                                            context); // BottomSheet zu
                                        Navigator.pop(context); // Screen zu
                                        await _db
                                            .collection('conversations')
                                            .doc(widget.conversationId)
                                            .delete();
                                      },
                                      child: const Text("Löschen",
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ));
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Gruppe löschen",
                        style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
  }

  // ---------- Load Other  User ----------

  Future<void> _loadOtherUser() async {
    final convDoc = await FirebaseFirestore.instance
        .collection("conversations")
        .doc(widget.conversationId)
        .get();

    if (!convDoc.exists) return;

    final data = convDoc.data()!;
    final members = List<String>.from(data['members']);
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    // other uid
    otherUserId = members.firstWhere((id) => id != currentUid);

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(otherUserId)
        .get();

    if (!userDoc.exists) {
      setState(() => userDeleted = true);
    }
  }

  // ---------- Deleted User ----------

  Future<void> _checkIfUserDeleted() async {
    final otherUserDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(otherUserId)
        .get();

    if (!otherUserDoc.exists) {
      setState(() => userDeleted = true);
    }
  }

  // ---------- Sart Video Call----------

  Future<void> _startVideoCall(Map<String, dynamic> convData) async {
    final members = List<String>.from(convData['members'] ?? []);

    final otherUserId = members.firstWhere(
      (m) => m != _user!.uid,
      orElse: () => "",
    );
>>>>>>> Stashed changes

    if (otherUserId.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callID: widget.conversationId,
          userID: _user!.uid,
          userName: _user!.email!,
        ),
      ),
    );

<<<<<<< Updated upstream
  if (result != null) {
    await _sendCallSummary(result);
    setState(() {});   
=======
    if (result != null) {
      await _sendCallSummary(result);
      setState(() {});
    }
>>>>>>> Stashed changes
  }

  // ---------- Send Call ----------

  Future<void> _sendCallSummary(Map<String, dynamic> call) async {
    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'type': 'call',
      'senderId': _user!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'callType': call['type'], // video
      'status': call['status'], // ended / missed
      'duration': call['duration'], // null if missed
    });

    await convRef.update({
      'lastMessage': call['status'] == 'missed'
          ? '📞 Verpasster Videoanruf'
          : '📞 Videoanruf beendet',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Typing indicator ----------

  Future<void> _setTyping(bool isTyping) async {
    if (_user == null) return;
    if (isTyping == _lastTypingState) return;

    _lastTypingState = isTyping;

    await _db.collection('conversations').doc(widget.conversationId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([_user!.uid])
          : FieldValue.arrayRemove([_user!.uid]),
    });
  }

  // ---------- Input change (typing + slash commands) ----------

  void _onTextChanged(String value) {
    _raw = value;
    _setTyping(value.trim().isNotEmpty);

    setState(() {
      _aktiveCmd = CommandRouter.detect(value);

      if (value.startsWith("/") && _aktiveCmd == null) {
        _isSlashToolbarVisible = true;
        _isAiPreviewVisible = false;
      } else {
        _isSlashToolbarVisible = false;
      }

      if (_aktiveCmd?.type == "tetris") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openTetris();
        });
      }
    });
  }

  // ---------- Basic send (text or command) ----------

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _user == null) return;

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;

      if (cmd.type == "hello") {
        await _sendHelloCommand(cmd);
        _resetInput();
        return;
      }
    }
      await FirebaseFirestore.instance
      .collection("users")
      .doc(_user!.uid)
      .update({
    "hiddenChats": FieldValue.arrayRemove([widget.conversationId])
     });
    if (mounted) setState(() {});
    setState(() => _sending = true);
    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        text: text,
        senderUid: _user!.uid,
        senderEmail: _user!.email ?? '',
      );

      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
      _setTyping(false);

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---------- Special send helpers (mini-apps) ----------

  Future<void> _sendHelloCommand(ChatCommand cmd) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final helloPayload = HelloApp.buildPayload(cmd.data);

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': helloPayload['type'] ?? 'app',
      'content': '',
      'payload': helloPayload['payload'] ?? {},
    });

    await convRef.update({
      'lastMessage': '👋 Hello',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendAiImage(String url) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);

    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'ai_image',
      'content': url,
    });

    await convRef.update({
      'lastMessage': '🤖🖼️ KI Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _sendTetrisScore(int score) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'app',
      'content': '',
      'payload': {
        'app': 'tetris',
        'data': {'score': score},
      },
    });

    await convRef.update({
      'lastMessage': '🎮 Tetris Score: $score',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendAiMessage({
    required String prompt,
    required String response,
  }) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'ai',
      'content': '',
      'payload': {
        'prompt': prompt,
        'response': response,
      },
    });

    await convRef.update({
      'lastMessage': '🤖 AI message',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendEventRef(String eventId) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'event_ref',
      'content': '',
      'eventId': eventId,
    });

    await convRef.update({
      'lastMessage': '📅 Event',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  void _resetInput() {
    setState(() {
      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
      _isSlashToolbarVisible = false;
      _isAiPreviewVisible = false;
    });
    _setTyping(false);
  }

  void _openReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ReactionPicker(
          onSelect: (emoji) {
            _toggleReaction(messageId, emoji);
          },
        );
      },
    );
  }

  // ---------- Reactions  ----------

  Future<void> _toggleReaction(String messageId, String emoji) async {
    if (_user == null) return;

    final msgRef = _db
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(messageId);

    final snap = await msgRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;

    final currentReaction = data['reaction'];

    if (currentReaction == emoji) {
      await msgRef.update({'reaction': FieldValue.delete()});
    } else {
      await msgRef.update({'reaction': emoji});
    }
  }

  // ---------- Images (gallery / camera) ----------

  Future<void> _sendImage(File file) async {
    if (_user == null) return;

    final filename =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';

    final ref = FirebaseStorage.instance.ref().child('chat_images/$filename');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _chatService.sendImageMessage(
      conversationId: widget.conversationId,
      url: url,
      senderUid: _user!.uid,
    );

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    await _sendImage(File(img.path));
    setState(() => _isSlashToolbarVisible = false);
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    await _sendImage(File(img.path));
    setState(() => _isSlashToolbarVisible = false);
  }

  void _openAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple,
                    child: IconButton(
                      icon: const Icon(Icons.image, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Gallery")
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Camera")
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Mini-apps UI helpers ----------

  void _toggleSlashToolbar() {
    setState(() {
      _isSlashToolbarVisible = !_isSlashToolbarVisible;
      if (_isSlashToolbarVisible) _isAiPreviewVisible = false;
    });
  }

  void _openAiPreview() {
    setState(() {
      _isAiPreviewVisible = true;
      _isSlashToolbarVisible = false;
      _aktiveCmd = null;
    });
  }

  void _openTetris() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TetrisFullScreenPage(
          onFinish: (score) {
            _sendTetrisScore(score);
          },
        ),
      ),
    );

    _resetInput();
  }

  // ---------- Formatting ----------

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    return DateFormat('HH:mm').format(ts.toDate());
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final justDate = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (justDate == today) return 'Today';
    if (justDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleMe = ChatTheme.myBubbleColor;
    final bubbleOther = isDark ? const Color(0xFF262D31) : Colors.white;

    // 🔥 Stream für live updates (Titeländerung)
    return StreamBuilder<DocumentSnapshot>(
        stream: _db
            .collection('conversations')
            .doc(widget.conversationId)
            .snapshots(),
        builder: (context, snapshot) {
          String displayTitle = widget.title;
          Map<String, dynamic>? convData;
          bool isGroup = false;

          if (snapshot.hasData && snapshot.data!.data() != null) {
            convData = snapshot.data!.data() as Map<String, dynamic>;
            isGroup = convData['isGroup'] == true;
            if (isGroup) {
              displayTitle = convData['name'] ?? widget.title;
            }
          }

<<<<<<< Updated upstream
        return Scaffold(
          // 🔥 WICHTIGE ÄNDERUNG: Hintergrund ist jetzt IMMER ChatTheme.backgroundColor
          // egal ob Dark Mode oder Light Mode aktiv ist.
          backgroundColor: ChatTheme.backgroundColor, 
          appBar: AppBar(
            backgroundColor: isDark ? Colors.grey[900] : ChatTheme.myBubbleColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: isGroup
                    ? const Icon(Icons.groups, color: Colors.white, size: 20)
                    : Text(
                        displayTitle.isNotEmpty
                            ? displayTitle[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    // Klick auf den Titel öffnet Einstellungen bei Gruppen
                    onTap: (isGroup && convData != null) 
                        ? () => _showGroupSettings(context, convData!) 
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isGroup) 
                          const Text("Tippen für Infos", style: TextStyle(color: Colors.white70, fontSize: 12))
                      ],
=======
          return Scaffold(
            backgroundColor: ChatTheme.backgroundColor,
            appBar: AppBar(
                backgroundColor:
                    isDark ? Colors.grey[900] : ChatTheme.myBubbleColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                title: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
>>>>>>> Stashed changes
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: isGroup
                          ? const Icon(Icons.groups,
                              color: Colors.white, size: 20)
                          : Text(
                              displayTitle.isNotEmpty
                                  ? displayTitle[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        // Klick auf den Titel öffnet Einstellungen bei Gruppen
                        onTap: (isGroup && convData != null)
                            ? () => _showGroupSettings(context, convData!)
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isGroup)
                              const Text("Tippen für Infos",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // 🔵 VIDEO CALL - PRIVATE CHAT
                  if (!isGroup && convData != null && !userDeleted)
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded,
                          color: Colors.white),
                      onPressed: () async {
                        final members =
                            List<String>.from(convData!['members'] ?? []);

                        final otherUserId = members.firstWhere(
                          (m) => m != _user!.uid,
                          orElse: () => "",
                        );

                        if (otherUserId.isEmpty) return;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callID: widget.conversationId,
                              userID: _user!.uid,
                              userName: _user!.email!,
                            ),
                          ),
                        );

                        if (result != null) {
                          await _sendCallSummary(result);
                          setState(() {});
                        }
                      },
                    ),

                  // 🔵 VIDEO CALL - GROUP
                  if (isGroup && convData != null)
                    IconButton(
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      onPressed: () {
                        final callID = widget.conversationId;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callID: callID,
                              userID: _user!.uid,
                              userName: _user!.email ?? "User",
                            ),
                          ),
                        );
                      },
                    ),
                ]),
            body: Stack(
              children: [
                Column(
                  children: [
                    // -------- Messages list --------
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            _chatService.messagesStream(widget.conversationId),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snap.data!.docs;
                          if (userDeleted) {
                            return Center(
                              child: Text(
                                "Dieser Benutzer existiert nicht mehr.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          if (docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Say hi 👋',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            reverse: true,
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            itemCount: docs.length + 2,
                            itemBuilder: (_, index) {
                              // Top encryption banner
                              if (index == docs.length + 1) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 4,
                                    left: 24,
                                    right: 24,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark
                                          ? const Color.fromARGB(
                                              200, 24, 34, 40)
                                          : const Color.fromARGB(
                                              148, 248, 236, 130),
                                    ),
                                    child: Text(
                                      '🔒 Messages are end-to-end encrypted. No one outside this chat can read them.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.yellow[200]
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              // First date chip (oldest message)
                              if (index == docs.length) {
                                final msgData = docs.last.data();
                                final ts = (msgData['timestamp'] ??
                                    msgData['time']) as Timestamp?;
                                final dt = ts?.toDate() ?? DateTime.now();
                                return _DateChip(label: _formatDateLabel(dt));
                              }

                              final msgIndex = index;
                              final msg = docs[msgIndex].data();
                              final senderEmail = msg['sender'] ?? '';
                              final isMe = msg['senderId'] == _user?.uid ||
                                  senderEmail == _user?.email;

                              final type = msg['type'] ?? 'text';
                              final ts = (msg['timestamp'] ?? msg['time'])
                                  as Timestamp?;
                              final dt = ts?.toDate() ?? DateTime.now();
                              final time = _formatTime(ts);

                              // Need date chip before this message?
                              bool showDateChip = false;
                              if (msgIndex < docs.length - 1) {
                                final nextMsg = docs[msgIndex + 1].data();
                                final nextTs = (nextMsg['timestamp'] ??
                                    nextMsg['time']) as Timestamp?;
                                final nextDt =
                                    nextTs?.toDate() ?? DateTime.now();

                                final d1 = DateTime(dt.year, dt.month, dt.day);
                                final d2 = DateTime(
                                    nextDt.year, nextDt.month, nextDt.day);
                                if (d1.difference(d2).inDays != 0) {
                                  showDateChip = true;
                                }
                              }

                              final bubble = _buildMessageBubble(
                                msg: msg,
                                isMe: isMe,
                                type: type,
                                time: time,
                                bubbleMe: bubbleMe,
                                bubbleOther: bubbleOther,
                              );

                              if (!showDateChip) return bubble;

                              return Column(
                                children: [
                                  _DateChip(label: _formatDateLabel(dt)),
                                  bubble,
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // -------- Typing indicator --------
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection("conversations")
                          .doc(widget.conversationId)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.data() == null) {
                          return const SizedBox(height: 0);
                        }

                        final data = snap.data!.data()!;
                        final typingUsers =
                            List<String>.from(data["typingUsers"] ?? []);
                        final members =
                            List<String>.from(data["members"] ?? []);

                        final me = _user?.uid;
                        final otherUid = members.firstWhere((m) => m != me,
                            orElse: () => "");

                        final isTyping = otherUid.isNotEmpty &&
                            typingUsers.contains(otherUid);

                        if (!isTyping) return const SizedBox(height: 0);

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 18,
                            bottom: 4,
                            top: 2,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                "typing…",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // -------- Input row (attach + ⚡ mini-apps + text + send) --------
                    _buildInput(isDark),
                  ],
                ),

                // Scroll to bottom FAB
                if (_showScrollBtn)
                  Positioned(
                    right: 12,
                    bottom: 90,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor:
                          isDark ? Colors.grey[800] : ChatTheme.myBubbleColor,
                      onPressed: () {
                        if (_scrollCtrl.hasClients) {
                          _scrollCtrl.animateTo(
                            0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: const Icon(Icons.arrow_downward, size: 20),
                    ),
                  ),

                // -------- Mini-apps overlays --------

                // Hello preview
                if (_aktiveCmd?.type == "hello")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: HelloPreview(
                      text: _aktiveCmd!.previewText!,
                      onCancel: _resetInput,
                      onSend: _send,
                    ),
                  ),

                // AI preview
                if (_isAiPreviewVisible)
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: AiPreview(
                      onCancel: () =>
                          setState(() => _isAiPreviewVisible = false),
                      onSend: (prompt, response) async {
                        await _sendAiMessage(
                            prompt: prompt, response: response);
                        setState(() => _isAiPreviewVisible = false);
                      },
                    ),
                  ),

                // Event preview
                if (_aktiveCmd?.type == "event")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: EventPreview(
                      onCancel: _resetInput,
                      onSend: (form) async {
                        final eventPayload = EventApp.buildPayload(form);
                        final doc = await _db.collection("events").add({
                          ...eventPayload,
                          "creator": _user!.email,
                        });

                        await _sendEventRef(doc.id);
                        _resetInput();
                      },
                    ),
                  ),

                // Slash mini-apps toolbar
                if (_isSlashToolbarVisible) _slashToolbar(),
              ],
            ),
          );
        });
  }

  // ---------- Build one message bubble (text + image + mini-apps) ----------
  Widget _buildMessageBubble({
    required Map<String, dynamic> msg,
    required bool isMe,
    required String type,
    required String time,
    required Color bubbleMe,
    required Color bubbleOther,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe ? bubbleMe : bubbleOther;
    final textColor =
        isMe ? Colors.white : (isDark ? Colors.white : Colors.black);
    final payload = msg['payload'] as Map<String, dynamic>?;
    final senderEmail = msg['sender'] ?? '';

    // ---------- REACTION (ONE PER MESSAGE) ----------
    final String? reaction = msg['reaction'];

    // ---------- IMAGE ----------
    if (type == 'image') {
      final url = (msg['content'] ?? payload?['url'] ?? '').toString();

      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openReactionPicker(msg['id']),
            child: _ImageBubble(
              imageUrl: url,
              time: time,
              isMe: isMe,
            ),
          ),
          if (reaction != null) _reactionChip(isMe, reaction),
        ],
      );
    }
    // ---------- CALL ----------

    if (type == 'call') {
      final status = msg['status'];
      final duration = msg['duration'];
      final callType = msg['callType'];

      String text = "";

      if (status == "missed") {
        text = "📞 Verpasster Videoanruf";
      } else {
        final minutes = (duration / 60).floor();
        final seconds = duration % 60;
        final durText =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        text = "📞 Videoanruf beendet – Dauer: $durText";
      }

      return _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        textColor: textColor,
        time: time,
        onLongPress: () => _openReactionPicker(msg['id']),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      );
    }

    // ---------- MINI APP ----------
    Widget bubbleWidget;

    if (type == 'app') {
      final appName = (payload?['app'] ?? '').toString();
      Widget child;

      if (appName == "tetris") {
        final score = payload?['data']?['score'] ?? 0;
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset, size: 26, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tetris Score",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text("Score: $score",
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
        );
      } else if (appName == "hello") {
        final who = payload?['data']?['who'] ?? 'there';
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("👋", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text("Hello $who!",
                style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600)),
          ],
        );
      } else {
        child = Text("App message", style: TextStyle(color: textColor));
      }

      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        child: child,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
      );
    }

    // ---------- AI IMAGE ----------
    else if (type == "ai_image") {
      final url = msg['content'] ?? "";

      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openReactionPicker(msg['id']),
            child: _ImageBubble(
              imageUrl: url,
              time: time,
              isMe: isMe,
            ),
          ),
          if (reaction != null) _reactionChip(isMe, reaction),
        ],
      );
    }

    // ---------- AI TEXT ----------
    else if (type == "ai") {
      final prompt = payload?['prompt'] ?? '';
      final response = payload?['response'] ?? '';

      bubbleWidget = GestureDetector(
        onLongPress: () => _openReactionPicker(msg['id']),
        child: _Bubble(
          isMe: isMe,
          bubbleColor: bubbleColor,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (prompt.toString().isNotEmpty)
                Text("Q: $prompt",
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white70 : Colors.black54)),
              if (prompt.toString().isNotEmpty) const SizedBox(height: 4),
              Text(response.toString(),
                  style: TextStyle(fontSize: 15, color: textColor)),
            ],
          ),
          time: time,
          textColor: textColor,
          senderName: isMe ? null : senderEmail.toString().split("@").first,
          onLongPress: () => _openReactionPicker(msg['id']),
        ),
      );
    }

    // ---------- EVENT REF ----------
    else if (type == 'event_ref') {
      final eventId = msg['eventId']?.toString();

      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        child: Text("📅 Event"),
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
      );
    }

    // ---------- TEXT ----------
    else {
      final text = msg['content'] ?? payload?['text'] ?? '';
      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        child: Text(text.toString(),
            style: TextStyle(fontSize: 17, color: textColor)),
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
      );
    }

    // ---------- FINAL RETURN (with reaction chip) ----------
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _openReactionPicker(msg['id']),
          child: bubbleWidget,
        ),
        if (reaction != null) _reactionChip(isMe, reaction),
      ],
    );
  }

  Widget _reactionChip(bool isMe, String emoji) {
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMe ? Colors.teal[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // ---------- Input row ----------

  Widget _buildInput(bool isDark) {
    // 🔥 FIX: Container ist jetzt außen, damit die Farbe bis ganz nach unten reicht
    if (userDeleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
        child: const Text(
          "Dieser Benutzer existiert nicht mehr.",
          style: TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }
    return Container(
      color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
      child: SafeArea(
        top:
            false, // Oben keine Safearea, damit es direkt an die Liste anschließt
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Text field (jetzt links)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Nachricht senden",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Attach (jetzt rechts)
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                onPressed: _openAttachmentMenu,
              ),

              // Mini-apps toggle (jetzt rechts)
              // 🔥 ICON GEÄNDERT zu Puzzle (Extension)
              IconButton(
                icon: Icon(
                  _isSlashToolbarVisible
                      ? Icons.extension
                      : Icons.extension_outlined,
                  color: ChatTheme.myBubbleColor,
                ),
                onPressed: _toggleSlashToolbar,
              ),

              const SizedBox(width: 2),

              // Send button (ganz rechts)
              CircleAvatar(
                backgroundColor: ChatTheme.myBubbleColor,
                child: IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _sending ? null : _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Slash (mini-apps) toolbar ----------

  Widget _slashToolbar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _commandCard(
              icon: "👋",
              title: "Hello",
              description: "Sende eine freundliche Nachricht",
              onTap: () {
                _ctrl.text = "/hello ";
                _onTextChanged("/hello ");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "🖼️",
              title: "Bild senden",
              description: "Wähle ein Bild aus der Galerie",
              onTap: _pickFromGallery,
            ),
            _commandCard(
              icon: "🧠",
              title: "KI Image",
              description: "Bild mit KI generieren",
              onTap: () async {
                setState(() => _isSlashToolbarVisible = false);

                final imageUrl = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ImageBotScreen()),
                );

                if (imageUrl != null && imageUrl is String) {
                  await _sendAiImage(imageUrl);
                }
              },
            ),
            _commandCard(
              icon: "🎮",
              title: "Tetris",
              description: "Spiele ein Mini-Tetris",
              onTap: () {
                _ctrl.text = "/tetris";
                _onTextChanged("/tetris");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "📅",
              title: "Event",
              description: "Erstelle ein Gruppen-Event",
              onTap: () {
                _ctrl.text = "/event";
                _onTextChanged("/event");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "🤖",
              title: "AI",
              description: "Chatte mit AI",
              onTap: _openAiPreview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final titleColor = isDarkMode ? Colors.white : Colors.black;
    final descColor = isDarkMode ? Colors.grey[400] : Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          color: cardColor,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: descColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Small helper widgets ----------

class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromARGB(200, 24, 34, 40)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final String time;
  final bool isMe;

  const _ImageBubble({
    required this.imageUrl,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 12 : 0),
      topRight: Radius.circular(isMe ? 0 : 12),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
              child: Image.network(
                imageUrl,
                width: 230,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Widget child;
  final String time;
  final bool isMe;
  final Color bubbleColor;
  final Color textColor;
  final String? senderName;
  final VoidCallback onLongPress;

  const _Bubble({
    required this.child,
    required this.time,
    required this.isMe,
    required this.bubbleColor,
    required this.textColor,
    this.senderName,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && senderName != null)
                Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 12 : 0),
                    topRight: Radius.circular(isMe ? 0 : 12),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    child,
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
