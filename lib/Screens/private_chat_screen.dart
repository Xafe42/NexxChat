import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

// Imports (Pfade ggf. anpassen)
import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../core/services/chat_service.dart';
import '../core/services/chat_theme.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_card.dart';
import '../widgets/event_preview.dart';
import '../widgets/hello_preview.dart'; 

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
  final _firestore = FirebaseFirestore.instance;
  final _chatService = ChatService();
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  
  late User? _user;
  String _raw = "";
  ChatCommand? _aktiveCmd;
  
  bool _isAiPreviewVisible = false;
  bool _isSlashToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  // --- LOGIK ---

  void _onChanged(String v) {
    setState(() {
      _raw = v;
      _aktiveCmd = CommandRouter.detect(v);

      if (v.startsWith("/") && _aktiveCmd == null) {
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
            // WICHTIG: Hier _sendMessage benutzen, damit es in den privaten Chat geht
            _sendMessage(type: 'app', payload: {
                'app': 'tetris',
                'data': {'score': score}
            });
          },
        ),
      ),
    );
    _resetInput();
  }

  // --- SENDEN (Privat) ---
  
  // Diese Methode schreibt direkt in die Sub-Collection 'messages' der Conversation
  Future<void> _sendMessage({required String type, required Map<String, dynamic> payload}) async {
    if (_user == null) return;
    
    await _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
      'type': type,
      'payload': payload,
      'sender': _user!.email,
      'senderId': _user!.uid,
      'time': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    String previewText = "Nachricht";
    if (type == 'image') previewText = "📷 Bild";
    if (type == 'app') previewText = "Interaktive App";
    if (type == 'text') previewText = payload['text'] ?? "Nachricht";

    await _firestore.collection('conversations').doc(widget.conversationId).update({
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendText() async {
    final txt = _raw.trim();
    if (txt.isEmpty || _user == null) return;

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;
      
      // 1. HELLO Command
      if (cmd.type == "hello") {
        final payload = HelloApp.buildPayload(cmd.data);
        await _sendMessage(type: 'app', payload: payload['payload']);
      }
      
      // 2. EVENT Command (Falls manuell getippt, meist über UI)
      // Die Logik für Events ist unten im EventPreview Widget
    } else {
      // Normale Textnachrichten über ChatService (standardisiert)
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        text: txt,
        senderUid: _user!.uid,
        senderEmail: _user!.email ?? '',
      );
    }
    _resetInput();
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || _user == null) return;
    
    final file = File(pickedFile.path);

    final filename = "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
    
    // Speichert direkt im Hauptordner chat_images (ohne Unterordner)
    final ref = FirebaseStorage.instance.ref().child("chat_images/$filename");

    try {
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // URL wird an ChatService übergeben
      await _chatService.sendImageMessage(
        conversationId: widget.conversationId,
        url: url,
        senderUid: _user!.uid,
      );
      
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fehler beim Hochladen des Bildes."))
        );
      }
    }
    
    setState(() => _isSlashToolbarVisible = false);
    _resetInput();
  }

  void _resetInput() {
    setState(() {
      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
      _isSlashToolbarVisible = false;
      _isAiPreviewVisible = false;
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.yellow[900], 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Text(widget.title.isNotEmpty ? widget.title[0].toUpperCase() : "?", 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // Stream aus dem ChatService (Private Nachrichten)
                  stream: _chatService.messagesStream(widget.conversationId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        return _buildMessageItem(data);
                      },
                    );
                  },
                ),
              ),
              _buildInputArea(isDarkMode),
            ],
          ),

          // --- PREVIEW LAYERS ---

          if (_aktiveCmd?.type == "hello")
            Positioned(
              bottom: 70, left: 0, right: 0,
              child: HelloPreview(
                text: _aktiveCmd!.previewText!,
                onCancel: _resetInput,
                onSend: _sendText,
              ),
            ),

          if (_isAiPreviewVisible)
            Positioned(
              bottom: 70, left: 0, right: 0,
              child: AiPreview(
                onCancel: () => setState(() => _isAiPreviewVisible = false),
                onSend: (prompt, response) async {
                  await _sendMessage(type: 'ai', payload: {
                    'prompt': prompt,
                    'response': response
                  });
                  setState(() => _isAiPreviewVisible = false);
                },
              ),
            ),

          if (_aktiveCmd?.type == "event")
            Positioned(
              bottom: 70, left: 0, right: 0,
              child: EventPreview(
                onCancel: _resetInput,
                onSend: (form) async {
                  final eventPayload = EventApp.buildPayload(form);
                  // Event selbst wird global gespeichert (optional, je nach Architektur)
                  final doc = await _firestore.collection("events").add({
                      ...eventPayload,
                      "creator": _user!.email,
                  });
                  // Referenz wird in den PRIVATEN Chat gesendet
                  await _sendMessage(type: 'event_ref', payload: {'eventId': doc.id});
                  _resetInput();
                },
              ),
            ),
          
          if (_isSlashToolbarVisible) _slashToolbar(),
        ],
      ),
    );
  }

  // --- MESSAGE ITEM BUILDER (Hier ist die Logik für Tetris/Events) ---
  Widget _buildMessageItem(Map<String, dynamic> data) {
    final senderEmail = data['sender'] ?? '';
    final isMe = _user?.email == senderEmail;
    final type = data['type'] ?? 'text';
    final payload = data['payload']; // Hier liegen die Tetris/App Daten

    Widget content;

    // 1. BILD (URL aus Storage)
    if (type == 'image') {
      final imageUrl = (data['content'] ?? data['payload']?['url'] ?? '').toString(); 
      if (imageUrl.isNotEmpty) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl, 
            width: 200, 
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: 200, height: 200, 
                child: const Center(child: CircularProgressIndicator())
              );
            },
          ),
        );
      } else {
        content = const Text("Bild Fehler");
      }
    } 
    // 2. HELLO WIDGET
    else if (type == 'app' && payload?['app'] == 'hello') {
        final who = payload?['data']?['who'] ?? 'World';
        content = HelloApp.buildCard(who.toString());
    } 
    // 3. TETRIS WIDGET (Fix)
    else if (type == 'app' && payload?['app'] == 'tetris') {
        final score = payload?['data']?['score'] ?? 0;
        content = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.videogame_asset, size: 30, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tetris Score",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    "Score: $score",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        );
    } 
    // 4. AI WIDGET
    else if (type == 'ai') {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q: ${payload?['prompt']}", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: isMe ? Colors.white70 : Colors.black54)),
            const Divider(),
            Text("${payload?['response']}", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
          ],
        );
    } 
    // 5. EVENT WIDGET (Fix)
    else if (type == 'event_ref') {
        final eventId = payload?['eventId'] ?? data['eventId'];
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('events').doc(eventId).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Text("Lade Event...");
            if (!snap.data!.exists) return const Text("Event gelöscht");
            
            final eventData = snap.data!.data() as Map<String, dynamic>;
            final ePayload = eventData['payload']['data'] ?? {};
            final votes = ePayload['votes'] ?? {'yes': [], 'maybe': [], 'no': []};
            
            return EventCard(
              title: ePayload['title'] ?? '',
              datetime: DateTime.tryParse(ePayload['datetime'] ?? ''),
              location: ePayload['location'] ?? '',
              description: ePayload['description'] ?? '',
              votes: votes,
              messageId: eventId, 
              currentUser: _user!.email!,
            );
          }
        );
    } 
    // 6. TEXT
    else {
      final text = data['content'] ?? payload?['text'] ?? '';
      content = Text(
        text.toString(),
        style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black),
      );
    }

    String timeStr = "";
    if (data['time'] != null && data['time'] is Timestamp) {
      final dt = (data['time'] as Timestamp).toDate();
      timeStr = DateFormat('HH:mm').format(dt);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) Text(senderEmail.split('@')[0], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? ChatTheme.myBubbleColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.orange, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: _onChanged,
                  maxLines: null,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Nachricht",
                    hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : const Color(0xFFF0F0F0),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isSlashToolbarVisible ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  size: 28, color: Colors.orange
                ),
                onPressed: _toggleSlashToolbar,
              ),
              ElevatedButton(
                onPressed: _sendText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatTheme.myBubbleColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Senden", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slashToolbar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Positioned(
      left: 0, right: 0, bottom: 80, 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _commandCard(icon: "👋", title: "Hello", description: "Sende eine freundliche Nachricht", onTap: () {
              _ctrl.text = "/hello "; _onChanged("/hello "); setState(() => _isSlashToolbarVisible = false);
            }),
            _commandCard(icon: "🖼️", title: "Bild senden", description: "Galerie", onTap: _sendImage),
            _commandCard(icon: "🎮", title: "Tetris", description: "Mini-Game", onTap: () {
              _ctrl.text = "/tetris"; _onChanged("/tetris"); setState(() => _isSlashToolbarVisible = false);
            }),
            _commandCard(icon: "📅", title: "Event", description: "Gruppen-Event", onTap: () {
              _ctrl.text = "/event"; _onChanged("/event"); setState(() => _isSlashToolbarVisible = false);
            }),
            _commandCard(icon: "🤖", title: "AI", description: "Chatte mit AI", onTap: _openAiPreview),
          ],
        ),
      ),
    );
  }

  Widget _commandCard({required String icon, required String title, required String description, required VoidCallback onTap}) { 
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black)),
                Text(description, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[400] : Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}