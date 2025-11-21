import 'package:cloud_firestore/cloud_firestore.dart'; // WICHTIG: Firestore Import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/people_screen.dart';

import 'chat_screen.dart';
import 'image_bot_screen.dart'; // <--- NEUER IMPORT (Dateinamen ggf. anpassen)
import 'settings_screen.dart';
import 'support_bot_screen.dart';
import 'welcome_screens.dart'; 

class ChatHomeScreen extends StatefulWidget {
  static const String screenRoute = "chat_home_screen";
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // Firestore Instanz
  int _selectedIndex = 0; 

  // Mock-Daten für die anderen Chats
  final List<Map<String, dynamic>> _staticChats = [
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
    // --- NEUER CHAT PARTNER ---
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
    // --------------------------
  ];

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // --- DARK MODE LOGIK ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    // -----------------------

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
      backgroundColor: bgColor, // Reagiert auf Dark Mode
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
          backgroundColor: bgColor, // Reagiert auf Dark Mode
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "People"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
          ],
        ),
      ),
      
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black, 
        child: const Icon(Icons.add, color: Colors.white),
      ) : null, 
    );
  }

  Widget _buildHeader(Color textColor, bool isDark) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        // CHATS TITLE
        Text(
          "Chats",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),

        const Spacer(),

        // SEARCH BUTTON (rounded)
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

  // 3. Die Chat Liste
  Widget _buildChatList(Color textColor, Color? subTextColor) {
    return ListView.builder(
      itemCount: 1 + _staticChats.length, 
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        
        if (index == 0) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('messages')
                .orderBy('time', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              String lastMessage = "Lade...";
              String time = "";
              int unread = 0; 

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                
                if (data['type'] == 'image') {
                  lastMessage = "📷 Foto";
                } else if (data['type'] == 'app' && data['payload']['app'] == 'tetris') {
                   lastMessage = "🎮 Tetris Score: ${data['payload']['data']['score']}";
                } else if (data['type'] == 'ai') {
                   lastMessage = "🤖 AI: ${data['payload']['response']}";
                } else if (data['type'] == 'event_ref') {
                   lastMessage = "📅 Neues Event";
                } else {
                  lastMessage = data['payload']?['text'] ?? "Nachricht";
                }
                time = _formatTimestamp(data['time']);
              } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                lastMessage = "Keine Nachrichten";
              }

              final liveChat = {
                "name": "Global Community",
                "message": lastMessage,
                "time": time,
                "avatar": "images/nexxchat.png",
                "icon": null,
                "isGroup": true,
                "unread": unread,
                "color": Colors.orange,
              };

              return _buildChatTile(liveChat, isLive: true, textColor: textColor, subTextColor: subTextColor);
            },
          );
        }

        final chat = _staticChats[index - 1];
        return _buildChatTile(chat, isLive: false, textColor: textColor, subTextColor: subTextColor);
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat, {required bool isLive, required Color textColor, required Color? subTextColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          if (chat['name'] == "Support Bot") {
             Navigator.push(
               context, 
               MaterialPageRoute(builder: (context) => SupportBotScreen())
             );
          } else if (chat['name'] == "AI Image Generator") { // --- NEUE NAVIGATION ---
             Navigator.push(
               context, 
               MaterialPageRoute(builder: (context) => ImageBotScreen())
             );
          } else if (isLive) { 
             Navigator.pushNamed(context, ChatScreen.screenRoute);
          } else {
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
                  Text(
                    chat['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    chat['message'], 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: (chat['unread'] as int) > 0 
                          ? textColor.withOpacity(0.8) 
                          : subTextColor,
                      fontWeight: (chat['unread'] as int) > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
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
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
      return Icon(
        chat['icon'] as IconData,
        color: chat['color'],
        size: 30,
      );
    }
    if (chat['avatar'] != null) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset(chat['avatar']),
      );
    }
    return Center(
      child: Text(
        (chat['name'] as String)[0],
        style: TextStyle(
          color: chat['color'],
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}