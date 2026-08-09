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

  void _activateAiInput() {
    setState(() {
      _ctrl.text = "/ai ";
      _ctrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
      _isSlashToolbarVisible = false;
    });
  }

  void _toggleSlashToolbar() =>
      setState(() => _isSlashToolbarVisible = !_isSlashToolbarVisible);

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
      _isSlashToolbarVisible = (v.startsWith("/") && _aktiveCmd == null);
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
                onFinish: (score) => _sendTetrisScore(score))));
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
        "data": {"score": score}
      },
      "sender": angemeldeterUser.email,
      "time": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _senden() async {
    final txt = _raw.trim();
    if (txt.isEmpty && _aktiveCmd == null) return;
    if (txt.startsWith("/ai ")) {
      final prompt = txt.replaceFirst("/ai ", "").trim();
      if (prompt.isEmpty) return;
      _ctrl.clear();
      _raw = "";
      await _firestore.collection("messages").add({
        "type": "text",
        "payload": {"text": "🤖 Frage an KI: $prompt"},
        "sender": angemeldeterUser.email,
        "time": FieldValue.serverTimestamp()
      });
      setState(() => _isAiLoading = true);
      try {
        final response = await fetchAi(prompt);
        await _firestore.collection("messages").add({
          "type": "ai",
          "payload": {"prompt": prompt, "response": response},
          "sender": "NexxAI",
          "time": FieldValue.serverTimestamp()
        });
      } finally {
        if (mounted) setState(() => _isAiLoading = false);
      }
      return;
    }
    if (_aktiveCmd?.type == "hello") {
      final payload = HelloApp.buildPayload(_aktiveCmd!.data);
      await _firestore.collection("messages").add({
        ...payload,
        "sender": angemeldeterUser.email,
        "time": FieldValue.serverTimestamp()
      });
    } else {
      await _firestore.collection("messages").add({
        "type": "text",
        "payload": {"text": txt},
        "sender": angemeldeterUser.email,
        "time": FieldValue.serverTimestamp()
      });
    }
    setState(() {
      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
    });
  }

  Future<void> _handleGlobalEventSend(Map<String, dynamic> data) async {
    final eventPayload = EventApp.buildPayload(data);
    final doc = await _firestore
        .collection("events")
        .add({...eventPayload, "creator": angemeldeterUser.email});
    await _firestore.collection("messages").add({
      "type": "event_ref",
      "eventId": doc.id,
      "sender": angemeldeterUser.email,
      "time": FieldValue.serverTimestamp()
    });
    setState(() {
      _isSlashToolbarVisible = false;
      _aktiveCmd = null;
      _ctrl.clear();
      _raw = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('images/nexxchat.png', height: 25)),
          const SizedBox(width: 10),
          const Text("Global Chat",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          if (_isAiLoading)
            const Padding(
                padding: EdgeInsets.only(left: 10),
                child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black)))
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context))
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: MessageStreamBuilder(
                  currentUserEmail: angemeldeterUser.email ?? "")),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildInteractionArea()),
          _buildBottomInput(isDark),
        ],
      ),
    );
  }

  Widget _buildInteractionArea() {
    if (_isSlashToolbarVisible) return _slashToolbar();
    if (_aktiveCmd?.type == "hello")
      return HelloPreview(
          text: _aktiveCmd!.previewText!,
          onCancel: () => setState(() => _aktiveCmd = null),
          onSend: _senden);
    if (_aktiveCmd?.type == "event")
      return EventPreview(
          onCancel: () => setState(() => _aktiveCmd = null),
          onSend: (data) => _handleGlobalEventSend(data));
    return const SizedBox.shrink();
  }

  Widget _buildBottomInput(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey[800] : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                        controller: _ctrl,
                        onChanged: _onChanged,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        decoration: const InputDecoration(
                            hintText: "Nachricht / Befehl...",
                            border: InputBorder.none)))),
            IconButton(
                icon: Icon(
                    _isSlashToolbarVisible
                        ? Icons.close
                        : Icons.add_circle_outline,
                    color: Colors.orange),
                onPressed: _toggleSlashToolbar),
            CircleAvatar(
                backgroundColor: ChatTheme.myBubbleColor,
                child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _senden)),
          ])),
    );
  }

  Widget _slashToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _commandCard(
              icon: "👋",
              title: "Hello",
              desc: "Sende Nachricht",
              tap: () {
                _ctrl.text = "/hello ";
                _onChanged("/hello ");
                setState(() => _isSlashToolbarVisible = false);
              }),
          _commandCard(
              icon: "🖼️", title: "Bild", desc: "Wähle Foto", tap: _sendImage),
          _commandCard(
              icon: "🎮", title: "Tetris", desc: "Mini-Game", tap: _openTetris),
          _commandCard(
              icon: "📅",
              title: "Event",
              desc: "Community-Event",
              tap: () {
                _ctrl.text = "/event";
                _onChanged("/event");
                setState(() => _isSlashToolbarVisible = false);
              }),
          _commandCard(
              icon: "🤖",
              title: "AI",
              desc: "Frag die KI",
              tap: _activateAiInput),
        ]));
  }

  Widget _commandCard(
      {required String icon,
      required String title,
      required String desc,
      required VoidCallback tap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: tap,
        child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                color: isDark ? Colors.grey[800] : Colors.white),
            child: Row(children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(desc,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey))
                  ]))
            ])));
  }
}
