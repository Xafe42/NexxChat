import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
late User signedInUser;

class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen';
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String? messageText;
  String? previewText; 

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        signedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  
  void handleInputChange(String value) {
    messageText = value;

    final raw = value;                 
    final t = value.trimRight();       

    String? nextPreview;

    if (t == '/hello') {
      nextPreview = '👋 Hello World from NexxChat!';
    } else if (t.startsWith('/hello ')) {
      final afterCmd = t.substring(7); 
      if (afterCmd.isNotEmpty) {
        
        final who = afterCmd.split(' ').first;
        if (who.isNotEmpty) {
          nextPreview = '👋 Hello $who from NexxChat!';
        }
      }
    }

    setState(() => previewText = nextPreview);
  }

  void resetInput() {
    setState(() {
      previewText = null;
      messageTextController.clear();
      messageText = '';
    });
  }

  Future<void> sendMessage() async {
    final text = messageText?.trim();
    if (text == null || text.isEmpty) return;

    if (text.startsWith('/hello')) {
     
      final afterCmd = text.length >= 7 ? text.substring(7).trimLeft() : '';
      final who = afterCmd.isNotEmpty ? afterCmd.split(' ').first : 'World';

      await _firestore.collection('messages').add({
        'type': 'app',
        'payload': {
          'app': 'hello',
          'data': {'who': who},
        },
        'sender': signedInUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('messages').add({
        'type': 'text',
        'payload': {'text': text},
        'sender': signedInUser.email,
        'time': FieldValue.serverTimestamp(),
      });
    }

    resetInput();
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MessageStreamBilder(),

            // Preview غير حاجز
            if (previewText != null)
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        previewText!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => previewText = null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),

           
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: handleInputChange,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        hintText: 'Write your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: sendMessage,
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

class MessageStreamBilder extends StatelessWidget {
  const MessageStreamBilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        List<MessageLine> messageWidgets = [];
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(backgroundColor: Colors.blue),
          );
        }

        final messages = snapshot.data!.docs.reversed;
        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final messageSender = data['sender'];
          final messageTime = data['time'];
          final currentUser = signedInUser.email;

          final messageType = data['type'] ?? 'text';
          String messageText = '';
          Widget? customAppWidget;

          if (messageType == 'app' && data['payload']?['app'] == 'hello') {
            final who = data['payload']?['data']?['who'] ?? 'World';
            customAppWidget = Card(
              color: Colors.amber[100],
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '👋 Hello $who from NexxChat!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          } else {
            if (data.containsKey('payload')) {
              final payload = data['payload'];
              messageText = payload['text'] ?? '';
            } else if (data.containsKey('text')) {
              messageText = data['text'];
            }
          }

          String formattedTime = '';
          if (messageTime != null && messageTime is Timestamp) {
            final date = messageTime.toDate();
            final hours = date.hour.toString().padLeft(2, '0');
            final minutes = date.minute.toString().padLeft(2, '0');
            formattedTime = "$hours:$minutes";
          }

          final messageWidget = MessageLine(
            sender: messageSender,
            text: messageText,
            appWidget: customAppWidget,
            isMe: currentUser == messageSender,
            time: formattedTime,
          );

          messageWidgets.add(messageWidget);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageLine extends StatelessWidget {
  const MessageLine({
    this.text,
    this.sender,
    required this.isMe,
    this.time,
    this.appWidget,
    Key? key,
  }) : super(key: key);

  final String? sender;
  final String? text;
  final String? time;
  final bool isMe;
  final Widget? appWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender ?? '',
              style: TextStyle(fontSize: 12, color: Colors.yellow[900])),
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
                  if (appWidget != null)
                    appWidget!
                  else
                    Text(
                      text ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black45,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    time ?? '',
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
