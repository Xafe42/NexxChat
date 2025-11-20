import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/chat_theme.dart';

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
          
          if (type == 'text') {
             final text = data['payload']?['text'] ?? '';
             content = Text(
               text.toString(),
               style: TextStyle(
                 fontSize: 15,
                 // Textfarbe anpassen
                 color: isMe ? Colors.white : Colors.black54,
               ),
             );
          } else {
             // Platzhalter falls du den Rest kopierst, 
             // nutze hier deinen existierenden Switch/If Code für den Content!
             content = Text("Inhalt"); 
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

// --- MESSAGE BUBBLE KLASSE (GANZ UNTEN IN DER DATEI) ---
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
            // 2. HIER DIE FARBE ANWENDEN:
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