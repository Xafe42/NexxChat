import 'dart:convert'; // Für Base64
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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

// Bild "hochladen" als Base64 direkt in Firestore
Future<String?> bildHochladen(XFile file) async {
  try {
    // Originalbild laden
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // Max. Größe setzen (1024px)
    const maxSize = 1024;
    if (image.width > maxSize || image.height > maxSize) {
      image = img.copyResize(image, width: maxSize, height: maxSize);
    }

    // Bild in Uint8List konvertieren und als Base64 encodieren
    final resizedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
    final base64Image = base64Encode(resizedBytes);

    return base64Image; // Kein Storage mehr nötig
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

  bool _isAiPreviewVisible = false;
  bool _isSlashToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) angemeldeterUser = user;
  }

  // AI Vorschau öffnen
  void _openAiPreview() {
    if (_aktiveCmd != null) setState(() => _aktiveCmd = null);
    setState(() {
      _isAiPreviewVisible = true;
      _isSlashToolbarVisible = false;
    });
  }

  // Slash Toolbar ein-/ausschalten
  void _toggleSlashToolbar() {
    if (_isAiPreviewVisible) setState(() => _isAiPreviewVisible = false);
    setState(() => _isSlashToolbarVisible = !_isSlashToolbarVisible);
  }

  // Bild senden ohne Storage
  Future<void> _sendImage() async {
    final file = await bildAuswaehlen();
    if (file != null) {
      final base64Image = await bildHochladen(file);
      if (base64Image != null) {
        await _firestore.collection('messages').add({
          'type': 'image',
          'payload': {'base64': base64Image}, // Base64 statt URL
          'sender': angemeldeterUser.email,
          'time': FieldValue.serverTimestamp(),
        });
      }
    }
    setState(() => _isSlashToolbarVisible = false);
  }

  // Textfeld Änderung: entscheidet über Toolbar oder Preview
  void _onChanged(String v) {
    setState(() {
      _raw = v;

      // Command erkennen
      _aktiveCmd = CommandRouter.detect(v);

      // Slash Toolbar nur anzeigen, wenn "/" eingegeben wird, aber kein Command erkannt wurde
      if (v.startsWith("/") && _aktiveCmd == null) {
        _isSlashToolbarVisible = true;
        _isAiPreviewVisible = false;
      } else {
        _isSlashToolbarVisible = false;
      }

      // Wenn ein Command erkannt wird, Vorschau öffnen
      if (_aktiveCmd != null) {
        _isAiPreviewVisible = false;
      }
    });
  }

  // Nachricht senden
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
                // Chat Input
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
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
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
                            icon: Icon(
                              _isSlashToolbarVisible
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              size: 28,
                              color: Colors.orange,
                            ),
                            onPressed: _toggleSlashToolbar,
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: _senden,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "Senden",
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.send, // Icon rechts
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vorschau Widgets für Commands
            if (_aktiveCmd?.type == "hello")
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: HelloPreview(
                  text: _aktiveCmd!.previewText!,
                  onCancel: () => setState(() => _aktiveCmd = null),
                  onSend: _senden,
                ),
              ),
            if (_aktiveCmd?.type == "tetris")
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: TetrisPreview(
                  onCancel: () => setState(() => _aktiveCmd = null),
                  onSend: _senden,
                ),
              ),
            if (_isAiPreviewVisible)
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: AiPreview(
                  onCancel: () => setState(() => _isAiPreviewVisible = false),
                  onSend: (prompt, response) async {
                    await _firestore.collection('messages').add({
                      'type': 'ai',
                      'payload': {'prompt': prompt, 'response': response},
                      'sender': angemeldeterUser.email,
                      'time': FieldValue.serverTimestamp(),
                    });
                    setState(() => _isAiPreviewVisible = false);
                  },
                ),
              ),
            if (_aktiveCmd?.type == "event")
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: EventPreview(
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
              ),

            // Slash Toolbar
            if (_isSlashToolbarVisible) _slashToolbar(),
          ],
        ),
      ),
    );
  }

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
              const SizedBox(height: 12),
              _commandCard(
                icon: "👋",
                title: "Hello",
                description: "Sende eine freundliche Nachricht",
                onTap: () {
                  _ctrl.text = "/hello ";
                  _onChanged("/hello ");
                  setState(() => _isSlashToolbarVisible = false);
                },
              ),
              _commandCard(
                icon: "🖼️",
                title: "Bild senden",
                description: "Wähle ein Bild aus der Galerie",
                onTap: _sendImage,
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "🎮",
                title: "Tetris",
                description: "Spiele ein Mini-Tetris",
                onTap: () {
                  _ctrl.text = "/tetris";
                  _onChanged("/tetris");
                  setState(() => _isSlashToolbarVisible = false);
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
                  setState(() => _isSlashToolbarVisible = false);
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "🤖",
                title: "AI",
                description: "Chatte mit AI",
                onTap: _openAiPreview,
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
