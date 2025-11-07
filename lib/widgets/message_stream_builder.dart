import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../apps/hello/hello_app.dart';
import '../widgets/tetris_container.dart';

final _firestore = FirebaseFirestore.instance; // Firestore-Instanz

class MessageStreamBuilder extends StatelessWidget {
  final String currentUserEmail; // E-Mail des aktuellen Benutzers
  const MessageStreamBuilder({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(), // Echtzeit-Stream der Nachrichten
      builder: (context, snapshot) {
        if (!snapshot.hasData) { // Ladeindikator, falls noch keine Daten
          return const Center(
            child: CircularProgressIndicator(backgroundColor: Colors.blue),
          );
        }

        final messages = snapshot.data!.docs.reversed; // Neueste Nachrichten unten
        final List<MessageBubble> messageWidgets = [];

        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final sender = (data['sender'] ?? '').toString();
          final time = data['time'];
          final type = data['type'] ?? 'text';
          final isMe = currentUserEmail == sender; // Prüft, ob die Nachricht vom aktuellen Benutzer stammt

          Widget content;
          if (type == 'app' && data['payload']?['app'] == 'hello') { // Spezieller App-Content
            final who = data['payload']?['data']?['who'] ?? 'World';
            content = HelloApp.buildCard(who.toString());
          } else if (type == 'tetris') { // Tetris-Nachricht
          content = Stack(
            children: [
              SingleChildScrollView( // Scrollbar hinzufügen
                scrollDirection: Axis.vertical, // Vertikales Scrollen
                child: TetrisContainer(), // Zeigt das Tetris-Spiel
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 28), // Deutlicher Button
                  onPressed: () {
                    message.reference.delete(); // Nachricht löschen
                  },
                ),
              ),
            ],
          );
          } else { // Normale Textnachricht
            final text = data['payload']?['text'] ?? '';
            content = Text(
              text.toString(),
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black54,
              ),
            );
          }

          // Formatiert Zeit als HH:MM
          String formattedTime = '';
          if (time != null && time is Timestamp) {
            final date = time.toDate();
            final h = date.hour.toString().padLeft(2, '0');
            final m = date.minute.toString().padLeft(2, '0');
            formattedTime = '$h:$m';
          }

          messageWidgets.add(
            MessageBubble(
              sender: sender,
              time: formattedTime,
              isMe: isMe,
              child: content,
            ),
          );
        }

        return ListView(
          reverse: true, // Neueste Nachrichten unten
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          children: messageWidgets,
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender; // Absender der Nachricht
  final Widget child; // Inhalt der Nachricht
  final String time; // Zeit der Nachricht
  final bool isMe; // Ob Nachricht vom aktuellen Benutzer stammt

  const MessageBubble({
    required this.sender,
    required this.child,
    required this.time,
    required this.isMe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10), // Außenabstand der Nachricht
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Ausrichtung je nach Absender
        children: [
          Text(
            sender, // Zeigt Absender an
            style: TextStyle(fontSize: 12, color: Colors.yellow[900]),
          ),
          Material(
            elevation: 5, // Schatten für Nachricht
            borderRadius: isMe
                ? const BorderRadius.only( // Runde Ecken für eigene Nachrichten
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : const BorderRadius.only( // Runde Ecken für fremde Nachrichten
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
            color: isMe ? Colors.blue[800] : Colors.white, // Hintergrundfarbe je nach Absender
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Textausrichtung
                children: [
                  child, // Nachrichtentext oder Widget
                  const SizedBox(height: 5), // Abstand zur Zeit
                  Text(
                    time, // Zeit der Nachricht
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
