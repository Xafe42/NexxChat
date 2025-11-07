import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../apps/hello/hello_app.dart';

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
          if (type == 'app' && data['payload']?['app'] == 'hello') {
            final who = data['payload']?['data']?['who'] ?? 'World';
            content = HelloApp.buildCard(who.toString());
          } else {
            final text = data['payload']?['text'] ?? '';
            content = Text(
              text.toString(),
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black54,
              ),
            );
          }

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
              child: content,
              time: formattedTime,
              isMe: isMe,
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
            color: isMe ? Colors.blue[800] : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
