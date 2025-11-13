import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../apps/hello_app.dart';
import '../apps/event_app.dart';

import '../core/models/chat_command.dart';
import '../core/commands/command_router.dart';

import '../widgets/hello_preview.dart';
import '../widgets/tetris_preview.dart';
import '../widgets/event_preview.dart';
import '../widgets/message_stream_builder.dart';

final _firestore = FirebaseFirestore.instance;
late User signedInUser;

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
  ChatCommand? _activeCmd;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) signedInUser = user;
  }

  // ◼ Update on typing
  void _onChanged(String v) {
    setState(() {
      _raw = v;
      _activeCmd = CommandRouter.detect(v);
    });
  }

  // ◼ SEND message or app command
  Future<void> _send() async {
    final txt = _raw.trim();
    if (txt.isEmpty) return;

    if (_activeCmd != null) {
      final cmd = _activeCmd!;

      // HELLO APP
      if (cmd.type == 'hello') {
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection('messages').add({
          ...payload,
          'sender': signedInUser.email,
        });
      }

      // EVENT APP → sending happens in EventPreview.onSend

    } else {
      await _firestore.collection('messages').add({
        'type': 'text',
        'payload': {'text': txt},
        'sender': signedInUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _ctrl.clear();
      _raw = '';
      _activeCmd = null;
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

            /// MAIN CHAT STREAM
            Column(
              children: [
                Expanded(
                  child: MessageStreamBuilder(
                    currentUserEmail: signedInUser.email ?? '',
                  ),
                ),

                /// PREVIEWS FOR COMMANDS
                if (_activeCmd?.type == "hello")
                  HelloPreview(
                    text: _activeCmd!.previewText!,
                    onCancel: () => setState(() => _activeCmd = null),
                    onSend: _send,
                  ),

                if (_activeCmd?.type == "tetris")
                  TetrisPreview(
                    onCancel: () => setState(() => _activeCmd = null),
                    onSend: _send,
                  ),

                if (_activeCmd?.type == "event")
                  EventPreview(
                    onCancel: () => setState(() => _activeCmd = null),
                    onSend: (formData) async {
                      final payload = EventApp.buildPayload(formData);
                      await _firestore.collection("messages").add({
                        ...payload,
                        "sender": signedInUser.email,
                      });

                      setState(() {
                        _ctrl.clear();
                        _activeCmd = null;
                        _raw = "";
                      });
                    },
                  ),

                /// MESSAGE INPUT
                Container(
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
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            hintText: 'Write your message here...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _send,
                        child: Text(
                          "Send",
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),

            /// CHATGPT-STYLE SLASH TOOLBAR
            if (_raw.trim() == "/") _slashToolbar(),
          ],
        ),
      ),
    );
  }

  // ◼ Floating white big popup (ChatGPT-style)
  Widget _slashToolbar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 70,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _commandCard(
                icon: "👋",
                title: "Hello",
                description: "Send a friendly hello message",
                onTap: () {
                  _ctrl.text = "/hello ";
                  _onChanged("/hello ");
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "🎮",
                title: "Tetris",
                description: "Play a mini Tetris game",
                onTap: () {
                  _ctrl.text = "/tetris";
                  _onChanged("/tetris");
                },
              ),
              const SizedBox(height: 12),
              _commandCard(
                icon: "📅",
                title: "Event",
                description: "Create a group event with voting",
                onTap: () {
                  _ctrl.text = "/event";
                  _onChanged("/event");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ◼ ONE BIG COMMAND CARD
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
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