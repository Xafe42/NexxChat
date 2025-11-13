import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../widgets/hello_preview.dart';
import '../widgets/message_stream_builder.dart';
import '../widgets/tetris_preview.dart';
import '../apps/event_app.dart';
import '../widgets/event_preview.dart';

final _firestore = FirebaseFirestore.instance; // Firestore-Instanz
late User signedInUser; // Aktuell eingeloggter Benutzer

class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen'; // Route für Navigator
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState(); // Erstellt den State
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController(); // Controller für TextField
  final _auth = FirebaseAuth.instance; // Firebase Auth Instanz

  String _raw = ''; // Rohtext des Eingabefelds
  ChatCommand? _activeCmd; // Aktives Chat-Kommando

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser; // Prüfen, ob Benutzer eingeloggt
    if (user != null) signedInUser = user; // Setzt aktuellen Benutzer
  }

  // Wird aufgerufen, wenn sich der Text im Eingabefeld ändert
  void _onChanged(String v) {
    _raw = v;
    setState(() => _activeCmd = CommandRouter.detect(v)); // Prüft auf Befehle
  }

  // Sendet die Nachricht oder das Kommando
  Future<void> _send() async {
    final txt = _raw.trim();
    if (txt.isEmpty) return; // Leere Nachrichten ignorieren

    if (_activeCmd != null) { // Wenn ein Kommando erkannt wurde
      final cmd = _activeCmd!;
      if (cmd.type == 'hello') { // Beispielkommando "hello"
        final payload = HelloApp.buildPayload(cmd.data);
        await _firestore.collection('messages').add({
          ...payload,
          'sender': signedInUser.email,
        });
      }
    } else { // Normale Textnachricht
      await _firestore.collection('messages').add({
        'type': 'text',
        'payload': {'text': txt},
        'sender': signedInUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _raw = ''; // Eingabefeld leeren
      _activeCmd = null; // Aktives Kommando zurücksetzen
      _ctrl.clear(); // Controller zurücksetzen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[900], // AppBar-Farbe
        title: Row(
          children: [
            Image.asset('images/nexxchat.png', height: 25), // Logo
            const SizedBox(width: 10),
            const Text('NexxChat'), // App-Name
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut(); // Abmelden
              Navigator.pop(context); // Zurück zur Willkommensseite
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
                currentUserEmail: signedInUser.email ?? '', // Nachrichtenstrom
              ),
            ),

           

            // Zeigt Vorschau für "hello"-Kommando an
            if (_activeCmd?.type == 'hello' && _activeCmd?.previewText != null)
              HelloPreview(
                text: _activeCmd!.previewText!,
                onCancel: () => setState(() => _activeCmd = null), // Abbrechen
                onSend: _send, // Senden
              ),
            // Zeigt Vorschau für "tetris"-Kommando an
            if (_activeCmd?.type == 'tetris')
              TetrisPreview(
                onCancel: () => setState(() => _activeCmd = null),
                onSend: _send,
              ),
            if (_activeCmd?.type == 'event')
              EventPreview(
                onCancel: () => setState(() => _activeCmd = null),
                onSend: (formData) async {
                  final payload = EventApp.buildPayload(formData);
                  await _firestore.collection('messages').add({
                    ...payload,
                    'sender': signedInUser.email,
                  });

                  setState(() {
                    _ctrl.clear();
                    _activeCmd = null;
                    _raw = '';
                  });
                },
              ),

            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.orange, width: 2)), // Trennlinie
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl, // Controller für Texteingabe
                      onChanged: _onChanged, // Textänderungen überwachen
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        hintText: 'Write your message here...', // Platzhalter
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _send, // Nachricht senden
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
