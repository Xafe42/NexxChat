import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart';

import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../widgets/ai_preview.dart'; // Hier liegt die fetchAi Logik
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

// Bild hochladen als Base64 (Ändern das die Bilder im Storage gespeichert werden)
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

  // Diese Variable steuert nun nicht mehr das AI Fenster, kann aber für Ladezustände genutzt werden
  bool _isAiLoading = false; 
  bool _isSlashToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) angemeldeterUser = user;
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  // Diese Methode wird jetzt direkt zum Starten der KI-Eingabe genutzt
  void _activateAiInput() {
    setState(() {
      _ctrl.text = "/ai ";
      _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
      _isSlashToolbarVisible = false;
    });
  }

  void _toggleSlashToolbar() {
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

    // --- INTEGRATION: DIREKTE KI ANFRAGE ---
    if (txt.startsWith("/ai ")) {
      final prompt = txt.replaceFirst("/ai ", "").trim();
      if (prompt.isEmpty) return;

      // Controller leeren für flüssiges Gefühl
      _ctrl.clear();
      _raw = "";
      
      // 1. Die Frage des Users als Nachricht anzeigen
      await _firestore.collection("messages").add({
        "type": "text",
        "payload": {"text": "🤖 Frage an KI: $prompt"},
        "sender": angemeldeterUser.email,
        "time": FieldValue.serverTimestamp(),
      });

      setState(() => _isAiLoading = true);

      try {
        // 2. KI Antwort holen
        final response = await fetchAi(prompt);

        // 3. Antwort als KI-Nachricht speichern
        await _firestore.collection("messages").add({
          "type": "ai",
          "payload": {
            "prompt": prompt,
            "response": response,
          },
          "sender": "NexxAI", // Spezial-Absender für Bot-Design
          "time": FieldValue.serverTimestamp(),
        });
      } finally {
        if (mounted) setState(() => _isAiLoading = false);
      }
      return;
    }

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;

      if (cmd.type == "hello") {
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection("messages").add({
          ...payload,
          "sender": angemeldeterUser.email,
          "time": FieldValue.serverTimestamp(), // Zeitstempel hinzugefügt
        });
      }

      if (cmd.type == "event") {
        // Logik für Event-Preview ist in build()
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        // Zurück-Button hinzugefügt
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Geht zurück zum Home Screen
          },
        ),
        title: Row(
          children: [
            Container(
               padding: const EdgeInsets.all(6),
               decoration: const BoxDecoration(
                 color: Colors.white,
                 shape: BoxShape.circle,
               ),
               child: Image.asset('images/nexxchat.png', height: 25),
            ),
            const SizedBox(width: 10),
            const Text(
                "NexxChat",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
            ),
            if (_isAiLoading) 
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
              )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
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
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.orange, width: 2),
                        ),
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
                                hintText: "Nachricht (Nutze /ai...)",
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
                              _isSlashToolbarVisible
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              size: 28,
                              color: Colors.orange,
                            ),
                            onPressed: _toggleSlashToolbar,
                          ),
                          ElevatedButton(
                            onPressed: _senden,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ChatTheme.myBubbleColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Senden",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
// SLASH MENU
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
              description: "Frag die KI direkt hier im Chat",
              onTap: _activateAiInput, // Nutzt die neue direkte Logik
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
            Expanded(
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}