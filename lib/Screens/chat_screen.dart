import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/chat_command.dart';
import '../core/commands/command_router.dart';
import '../apps/hello/hello_app.dart';
import '../widgets/hello_preview.dart';
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

  void _onChanged(String v) {
    _raw = v;
    setState(() => _activeCmd = CommandRouter.detect(v));
  }

  Future<void> _send() async {
    final txt = _raw.trim();
    if (txt.isEmpty) return;

    if (_activeCmd != null) {
      final cmd = _activeCmd!;
      if (cmd.type == 'hello') {
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection('messages').add({
          ...payload,
          'sender': signedInUser.email,
        });
      }
    } else {
      await _firestore.collection('messages').add({
        'type': 'text',
        'payload': {'text': txt},
        'sender': signedInUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _raw = '';
      _activeCmd = null;
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        title: Row(
          children: [
            Image.asset('images/logo.jpeg', height: 25),
            const SizedBox(width: 10),
            const Text('MessageMe'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessageStreamBuilder(
                currentUserEmail: signedInUser.email ?? '',
              ),
            ),
            if (_activeCmd?.type == 'hello' && _activeCmd?.previewText != null)
              HelloPreview(
                text: _activeCmd!.previewText!,
                onCancel: () => setState(() => _activeCmd = null),
                onSend: _send,
              ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.orange, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _onChanged,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        hintText: 'Write your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _send,
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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
