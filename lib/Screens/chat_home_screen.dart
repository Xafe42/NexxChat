import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/people_screen.dart';

import 'chat_screen.dart';
import 'image_bot_screen.dart';
import 'private_chat_screen.dart';
import 'settings_screen.dart';
import 'support_bot_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  static const String screenRoute = "chat_home_screen";
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  User? currentUser;

  // Mock-Daten für die statischen Chats (außer Global Chat)
  final List<Map<String, dynamic>> _staticChats = [
    // Index 0: Event Planung (Beispiel) oder du entfernst es, wenn nicht gewollt
    {
      "name": "Event Planung",
      "message": "Wann geht es los?",
      "time": "09:41",
      "avatar": null,
      "icon": null,
      "isGroup": true,
      "unread": 0,
      "color": Colors.blue,
    },
    // Index 1: Support Bot
    {
      "name": "Support Bot",
      "message": "Ich bin bereit für AI Fragen...",
      "time": "Gestern",
      "avatar": null,
      "icon": Icons.smart_toy_rounded,
      "isGroup": false,
      "unread": 0,
      "color": Colors.purple,
    },
    // Index 2: AI Image Generator
    {
      "name": "AI Image Generator",
      "message": "Ich bin bereit dir Bilder zu generieren!",
      "time": "Neu",
      "avatar": null,
      "icon": Icons.palette_rounded,
      "isGroup": false,
      "unread": 0,
      "color": Colors.pink,
    },
  ];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;

    final List<Widget> pages = [
      Column(
        children: [
          _buildHeader(textColor, isDarkMode),
          Expanded(child: _buildChatList(textColor, subTextColor)),
        ],
      ),
      const PeopleScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.orange[800],
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: bgColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded), label: "People"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: "Settings"),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Wechselt zum People Tab
                });
              },
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            "Chats",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: textColor),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(Color textColor, Color? subTextColor) {
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Stream der privaten Unterhaltungen aus Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('conversations')
          .where('members', arrayContains: currentUser!.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        // --- 1. Globaler Chat Tile (immer ganz oben) ---
        final globalChatTile = StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('messages')
              .orderBy('time', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, msgSnapshot) {
            String lastMessage = "Lade...";
            String time = "";
            if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
              final data =
                  msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
              if (data['type'] == 'image') {
                lastMessage = "📷 Foto";
              } else if (data['type'] == 'app') {
                lastMessage = "App Aktivität";
              } else {
                lastMessage = data['payload']?['text'] ?? "Nachricht";
              }
              time = _formatTimestamp(data['time']);
            } else {
              lastMessage = "Keine Nachrichten";
            }
            final liveChat = {
              "name": "Global Community",
              "message": lastMessage,
              "time": time,
              "avatar": "images/nexxchat.png",
              "isGroup": true,
              "unread": 0,
              "color": Colors.orange,
            };
            return _buildChatTile(liveChat,
                isLive: true, textColor: textColor, subTextColor: subTextColor);
          },
        );

        final conversations = snapshot.hasData ? snapshot.data!.docs : [];

        // Gesamtliste: 
        // 1. Global Chat
        // 2. Statische Chats (Support Bot, AI Bot, etc.)
        // 3. Dynamische Chats aus Firestore
        final totalCount = 1 + _staticChats.length + conversations.length;

        return ListView.builder(
          itemCount: totalCount,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemBuilder: (context, index) {
            // Index 0: Globaler Chat
            if (index == 0) return globalChatTile;

            // Index 1 bis staticChats.length: Statische Chats
            if (index <= _staticChats.length) {
              final chat = _staticChats[index - 1];
              return _buildChatTile(chat, isLive: false, textColor: textColor, subTextColor: subTextColor);
            }

            // Ab hier: Dynamische Chats aus Firestore
            // Wir müssen den Index korrigieren: index - (1 + staticChats.length)
            final convIndex = index - (1 + _staticChats.length);
            final convDoc = conversations[convIndex];
            final convData = convDoc.data() as Map<String, dynamic>;
            final members = List<String>.from(convData['members']);
            final otherUid = members.firstWhere((id) => id != currentUser!.uid,
                orElse: () => "");

            // Daten des Chatpartners laden
            return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUid).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final name = userData?['fullName'] ?? "Unbekannt";

                  final lastMsg = convData['lastMessage'] ?? "";
                  final ts = convData['lastMessageTime'] as Timestamp?;
                  final timeStr = _formatTimestamp(ts);

                  final chatMap = {
                    "name": name,
                    "message": lastMsg,
                    "time": timeStr,
                    "avatar": null,
                    "icon": null,
                    "isGroup": false,
                    "unread": 0,
                    "color": Colors.blue,
                    "docId": convDoc.id, // WICHTIG für Navigation
                  };
                  return _buildChatTile(chatMap,
                      isLive: false,
                      textColor: textColor,
                      subTextColor: subTextColor);
                });
          },
        );
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat,
      {required bool isLive,
      required Color textColor,
      required Color? subTextColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          if (chat['name'] == "Support Bot") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SupportBotScreen()));
          } else if (chat['name'] == "AI Image Generator") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ImageBotScreen()));
          } else if (isLive) {
            Navigator.pushNamed(context, ChatScreen.screenRoute);
          } else if (chat['docId'] != null) {
            // Navigation zum Private Chat (nur wenn docId vorhanden)
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PrivateChatScreen(
                          conversationId: chat['docId'],
                          title: chat['name'],
                        )));
          } else {
             // Fallback für statische Chats ohne spezielle Navigation (z.B. "Event Planung")
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Dieser Chat ist noch nicht verbunden."))
             );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (chat['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _buildAvatarContent(chat),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat['name'],
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 5),
                  Text(
                    chat['message'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat['time'],
                    style: TextStyle(fontSize: 12, color: subTextColor)),
                const SizedBox(height: 5),
                if ((chat['unread'] as int) > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat['unread'].toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(Map<String, dynamic> chat) {
    if (chat['icon'] != null) {
      return Icon(chat['icon'] as IconData, color: chat['color'], size: 30);
    }
    if (chat['avatar'] != null) {
      return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(chat['avatar']));
    }
    return Center(
        child: Text(
            (chat['name'] as String).isNotEmpty
                ? (chat['name'] as String)[0].toUpperCase()
                : "?",
            style: TextStyle(
                color: chat['color'],
                fontWeight: FontWeight.bold,
                fontSize: 20)));
  }
}