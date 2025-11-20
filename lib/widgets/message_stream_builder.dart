import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../apps/hello_app.dart';
import '../core/chat_theme.dart';
import '../widgets/event_card.dart'; 

final _firestore = FirebaseFirestore.instance;

class MessageStreamBuilder extends StatelessWidget {
  final String currentUserEmail;
  const MessageStreamBuilder({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(backgroundColor: Colors.blue),
          );
        }

        final messages = snapshot.data!.docs.reversed;
        final List<MessageBubble> messageWidgets = [];

        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final sender = (data['sender'] ?? '').toString();
          final time = data['time'];
          final type = data['type'] ?? 'text';
          final isMe = currentUserEmail == sender;

          Widget content;

          // --- TYPEN UNTERSCHEIDUNG ---

          // 1. HELLO APP
          if (type == 'app' && data['payload']?['app'] == 'hello') {
            final who = data['payload']?['data']?['who'] ?? 'World';
            content = HelloApp.buildCard(who.toString());
          }
          // 2. TETRIS APP
          else if (type == 'app' && data['payload']?['app'] == 'tetris') {
            final score = data['payload']?['data']?['score'] ?? 0;
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Score: $score",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          // 3. EVENT REFERENCE
          else if (type == 'event_ref') {
            final eventId = data['eventId'];
            content = StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('events').doc(eventId).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Text("Loading event...");
                }
                final eventData = snap.data!.data() as Map<String, dynamic>;
                final payload = eventData['payload']['data'] ?? {};
                final votes = payload['votes'] ?? {'yes': [], 'maybe': [], 'no': []};

                return EventCard(
                  title: payload['title'] ?? '',
                  datetime: DateTime.tryParse(payload['datetime'] ?? ''),
                  location: payload['location'] ?? '',
                  description: payload['description'] ?? '',
                  votes: votes,
                  messageId: eventId,
                  currentUser: currentUserEmail,
                );
              },
            );
          }
          // 4. IMAGE MESSAGE
          else if (type == 'image') {
            final base64Str = data['payload']?['base64'] ?? '';
            if (base64Str.isNotEmpty) {
              final bytes = base64Decode(base64Str);
              content = Image.memory(
                bytes,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              );
            } else {
              content = const SizedBox();
            }
          }
          // 5. AI MESSAGE
          else if (type == 'ai') {
             final prompt = data['payload']?['prompt'] ?? '';
             final response = data['payload']?['response'] ?? '';
             content = Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   "Q: $prompt", 
                   style: TextStyle(
                     fontStyle: FontStyle.italic, 
                     fontSize: 12, 
                     color: isMe ? Colors.white70 : Colors.black54
                   )
                 ),
                 const Divider(color: Colors.grey),
                 Text(
                   response.toString(),
                   style: TextStyle(
                     fontSize: 15,
                     color: isMe ? Colors.white : Colors.black87,
                   ),
                 ),
               ],
             );
          }
          // 6. DEFAULT TEXT MESSAGE
          else {
            final text = data['payload']?['text'] ?? '';
            content = Text(
              text.toString(),
              style: TextStyle(
                fontSize: 15,
                // Textfarbe: Weiß wenn eigene Nachricht (auf farbigem Hintergrund), sonst Schwarz
                color: isMe ? Colors.white : Colors.black87,
              ),
            );
          }

          // Format HH:MM
          String formattedTime = '';
          if (time != null && time is Timestamp) {
            final date = time.toDate();
            formattedTime =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          children: messageWidgets,
        );
      },
    );
  }
}

// MESSAGE BUBBLE KLASSE
class MessageBubble extends StatelessWidget {
  final String sender;
  final Widget child;
  final String time;
  final bool isMe;

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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.yellow[900]),
          ),
          Material(
            elevation: 5,
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
            // Personalisiertes Theme für eigene Nachrichten, Weiß für andere
            color: isMe ? ChatTheme.myBubbleColor : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  child,
                  const SizedBox(height: 5),
                  Text(
                    time,
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