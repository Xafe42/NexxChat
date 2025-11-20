import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nexxchat_firebase/core/app_colors.dart';

import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_preview.dart';
import '../widgets/hello_preview.dart';
import '../widgets/message_stream_builder.dart';

final _firestore = FirebaseFirestore.instance;
late User angemeldeterUser;

// Bild auswählen
Future<XFile?> bildAuswaehlen() async {
  final picker = ImagePicker();
  return await picker.pickImage(source: ImageSource.gallery);
}

// Bild hochladen als Base64
Future<String?> bildHochladen(XFile file) async {
  try {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    const maxSize = 1024;
    if (image.width > maxSize || image.height > maxSize) {
      image = img.copyResize(image, width: maxSize, height: maxSize);
    }

    final resizedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
    return base64Encode(resizedBytes);
  } catch (e) {
    print('Upload Fehler: $e');
    return null;
  }
}

class ChatScreen extends StatefulWidget {
  static const String screenRoute = "chat_screen";
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String _raw = "";
  ChatCommand? _aktiveCmd;

  bool _isAiPreviewVisible = false;
  bool _isSlashToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) angemeldeterUser = user;
  }

  void _openAiPreview() {
    if (_aktiveCmd != null) setState(() => _aktiveCmd = null);
    setState(() {
      _isAiPreviewVisible = true;
      _isSlashToolbarVisible = false;
    });
  }

  void _toggleSlashToolbar() {
    if (_isAiPreviewVisible) setState(() => _isAiPreviewVisible = false);
    setState(() => _isSlashToolbarVisible = !_isSlashToolbarVisible);
  }

  Future<void> _sendImage() async {
    final file = await bildAuswaehlen();
    if (file != null) {
      final base64Image = await bildHochladen(file);
      if (base64Image != null) {
        await _firestore.collection('messages').add({
          'type': 'image',
          'payload': {'base64': base64Image},
          'sender': angemeldeterUser.email,
          'time': FieldValue.serverTimestamp(),
        });
      }
    }
    setState(() => _isSlashToolbarVisible = false);
  }

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

    setState(() {
      _aktiveCmd = null;
      _raw = "";
      _ctrl.clear();
    });
  }

  
  Future<void> _sendTetrisScore(int score) async {
    await _firestore.collection("messages").add({
      "type": "app",
      "payload": {
        "app": "tetris",
        "data": {"score": score},
      },
      "sender": angemeldeterUser.email,
      "time": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _senden() async {
    final txt = _raw.trim();
    if (txt.isEmpty) return;

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;

      if (cmd.type == "hello") {
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection("messages").add({
          ...payload,
          "sender": angemeldeterUser.email,
        });
      }

      if (cmd.type == "event") {
        
      }
    } else {
      await _firestore.collection("messages").add({
        "type": "text",
        "payload": {"text": txt},
        "sender": angemeldeterUser.email,
        "time": FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primarylight,
        // Zurück-Button hinzugefügt
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Geht zurück zum Home Screen
          },
        ),
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
                    currentUserEmail: angemeldeterUser.email ?? "",
                  ),
                ),

                // INPUT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primaryDark, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onChanged: _onChanged,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: "Schreibe deine Nachricht",
                            filled: true,
                            fillColor: AppColors.textFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isSlashToolbarVisible
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline,
                          size: 28,
                          color: AppColors.primarylight,
                        ),
                        onPressed: _toggleSlashToolbar,
                      ),
                      ElevatedButton(
                        onPressed: _senden,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Senden",
                            style: TextStyle(color: AppColors.textLight)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // HELLO Preview
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

            // AI Preview
            if (_isAiPreviewVisible)
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: AiPreview(
                  onCancel: () => setState(() => _isAiPreviewVisible = false),
                  onSend: (prompt, response) async {
                    await _firestore.collection("messages").add({
                      "type": "ai",
                      "payload": {
                        "prompt": prompt,
                        "response": response,
                      },
                      "sender": angemeldeterUser.email,
                      "time": FieldValue.serverTimestamp(),
                    });
                    setState(() => _isAiPreviewVisible = false);
                  },
                ),
              ),

            // EVENT Preview
            if (_aktiveCmd?.type == "event")
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: EventPreview(
                  onCancel: () => setState(() => _aktiveCmd = null),
                  onSend: (form) async {
                    final eventPayload = EventApp.buildPayload(form);
                    final doc = await _firestore.collection("events").add({
                      ...eventPayload,
                      "creator": angemeldeterUser.email,
                    });

                    await _firestore.collection("messages").add({
                      "type": "event_ref",
                      "eventId": doc.id,
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

  // SLASH MENU
  Widget _slashToolbar() {
    // ... (Toolbar Code bleibt gleich) ...
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.boxColorDark.withOpacity(0.18),
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
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "🖼️",
              title: "Bild senden",
              description: "Wähle ein Bild aus der Galerie",
              onTap: _sendImage,
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputFill),
          color: AppColors.background,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                Text(description,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}