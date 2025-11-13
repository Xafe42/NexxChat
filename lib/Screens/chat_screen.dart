import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_preview.dart';
import '../widgets/hello_preview.dart';
import '../widgets/message_stream_builder.dart';
import '../widgets/tetris_preview.dart';

final _firestore = FirebaseFirestore.instance;
late User angemeldeterUser;

// Bild auswählen
Future<XFile?> bildAuswaehlen() async {
  final picker = ImagePicker();
  return await picker.pickImage(source: ImageSource.gallery);
}

// Bild hochladen
Future<String?> bildHochladen(XFile file) async {
  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_bilder/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await storageRef.putFile(File(file.path));
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print('Upload Fehler: $e');
    return null;
  }
}

class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen';
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String _raw = '';
  ChatCommand? _aktiveCmd;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) angemeldeterUser = user;
  }

  void _onChanged(String v) {
    setState(() {
      _raw = v;
      if (v.startsWith('/ai')) {
        final prompt = v.length > 3 ? v.substring(3).trim() : '';
        _aktiveCmd = ChatCommand(
          type: 'ai',
          data: {'prompt': prompt},
          previewText: null,
        );
      } else {
        _aktiveCmd = CommandRouter.detect(v);
      }
    });
  }

  Future<void> _senden() async {
    final txt = _raw.trim();
    if (txt.isEmpty) return;

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;
      if (cmd.type == 'hello') {
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection('messages').add({
          ...payload,
          'sender': angemeldeterUser.email,
        });
      }
      if (cmd.type == 'tetris') {
        final payload = {
          "type": "app",
          "payload": {
            "app": "tetris",
            "data": {"score": cmd.data["score"] ?? 0},
          },
          "time": FieldValue.serverTimestamp(),
        };
        await _firestore.collection('messages').add({
          ...payload,
          "sender": angemeldeterUser.email,
        });
      }
    } else {
      await _firestore.collection('messages').add({
        'type': 'text',
        'payload': {'text': txt},
        'sender': angemeldeterUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _ctrl.clear();
      _raw = '';
      _aktiveCmd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        title: Row(
          children: [
            Image.asset('images/nexxchat.png', height: 25),
            const SizedBox(width: 10),
            const Text("NexxChat"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: MessageStreamBuilder(
                    currentUserEmail: angemeldeterUser.email ?? '',
                  ),
                ),

                // Vorschau Widgets für Commands
                if (_aktiveCmd?.type == "hello")
                  HelloPreview(
                    text: _aktiveCmd!.previewText!,
                    onCancel: () => setState(() => _aktiveCmd = null),
                    onSend: _senden,
                  ),
                if (_aktiveCmd?.type == "tetris")
                  TetrisPreview(
                    onCancel: () => setState(() => _aktiveCmd = null),
                    onSend: _senden,
                  ),
                if (_aktiveCmd?.type == "ai")
                  AiPreview(
                    onCancel: () => setState(() => _aktiveCmd = null),
                    onSend: (prompt, response) async {
                      await _firestore.collection('messages').add({
                        'type': 'ai',
                        'payload': {'prompt': prompt, 'response': response},
                        'sender': angemeldeterUser.email,
                        'time': FieldValue.serverTimestamp(),
                      });
                      setState(() => _aktiveCmd = null);
                    },
                  ),
                if (_aktiveCmd?.type == "event")
                  EventPreview(
                    onCancel: () => setState(() => _aktiveCmd = null),
                    onSend: (formData) async {
                      final payload = EventApp.buildPayload(formData);
                      final eventDoc = await _firestore
                          .collection("events")
                          .add({...payload, "creator": angemeldeterUser.email});
                      await _firestore.collection("messages").add({
                        "type": "event_ref",
                        "eventId": eventDoc.id,
                        "sender": angemeldeterUser.email,
                        "time": FieldValue.serverTimestamp(),
                      });
                      setState(() {
                        _ctrl.clear();
                        _aktiveCmd = null;
                        _raw = "";
                      });
                    },
                  ),

                // Chat Input mit Bild-Button links vom Senden
                Container(
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
                          maxLines: null, // Mehrzeilige Eingabe
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            hintText: 'Schreibe deine Nachricht',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF0F0F0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, size: 28, color: Colors.orange),
                            onPressed: () async {
                              final file = await bildAuswaehlen();
                              if (file != null) {
                                final url = await bildHochladen(file);
                                if (url != null) {
                                  await _firestore.collection('messages').add({
                                    'type': 'image',
                                    'payload': {'url': url},
                                    'sender': angemeldeterUser.email,
                                    'time': FieldValue.serverTimestamp(),
                                  });
                                }
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: _senden,
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              "Senden",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Toolbar
                if (_raw.trim() == "/") _slashToolbar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Toolbar
  Widget _slashToolbar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
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
                  _onChanged("/hello ");
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "🎮",
                title: "Tetris",
                description: "Spiele ein Mini-Tetris",
                onTap: () {
                  _ctrl.text = "/tetris";
                  _onChanged("/tetris");
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "📅",
                title: "Event",
                description: "Erstelle ein Gruppen-Event",
                onTap: () {
                  _ctrl.text = "/event";
                  _onChanged("/event");
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "🤖",
                title: "AI",
                description: "Chatte mit AI",
                onTap: () {
                  _ctrl.text = "/ai ";
                  _onChanged("/ai ");
                },
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
