import 'package:cloud_firestore/cloud_firestore.dart'; // WICHTIG: Firestore Import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/people_screen.dart';

import '../core/chat_theme.dart';
import 'chat_screen.dart';
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

  // Mock-Daten für die anderen Chats (die nicht in Firestore sind)
  final List<Map<String, dynamic>> _staticChats = [
    // Index 0 ist reserviert für Global Community (wird unten dynamisch geladen)
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
  ];

  // Hilfsfunktion: Zeitstempel formatieren (z.B. 14:30)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkBg = ChatTheme.backgroundColor.computeLuminance() < 0.5;
    Color textColor = isDarkBg ? Colors.white : Colors.black;

    final List<Widget> pages = [
      Column(
        children: [
           _buildHeader(textColor),
           Expanded(child: _buildChatList(textColor)), 
        ],
      ),
      const PeopleScreen(),
      const SettingsScreen(), 
    ];

    return Scaffold(
      backgroundColor: Colors.white,
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
          onTap: (index) {
             setState(() => _selectedIndex = index);
             _loadTheme();
          },
          selectedItemColor: Colors.orange[800],
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: ChatTheme.backgroundColor, 
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "People"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
          ],
        ),
      ),
      
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          // Neuer Chat Logik
        },
        backgroundColor: ChatTheme.myBubbleColor, 
        child: const Icon(Icons.add, color: Colors.white),
      ) : null, 
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Chats",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200], 
                  shape: BoxShape.circle
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200], 
                  shape: BoxShape.circle
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: () {
                    _auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, WelcomeScreen.screenRoute, (route) => false);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // 3. Die Chat Liste
  Widget _buildChatList(Color textColor) {
    // ListView mit itemCount + 1 (1 für den Live Chat, der Rest statisch)
    return ListView.builder(
      itemCount: 1 + _staticChats.length, 
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        
        // --- FALL 1: Der erste Chat (Index 0) ist der ECHTE Firebase Chat ---
        if (index == 0) {
          return StreamBuilder<QuerySnapshot>(
            // Holen der letzte Nachricht, sortiert nach Zeit
            stream: _firestore
                .collection('messages')
                .orderBy('time', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              String lastMessage = "Lade...";
              String time = "";
              // Ungelesen Logic ist komplex ohne User-Tracking, wir setzen vorerst 0
              // oder könnten z.B. einfach immer anzeigen wenn ungelesen
              int unread = 0; 

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                
                // Prüfen was für ein Typ Nachricht es ist
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
                
                // Zeit formatieren
                time = _formatTimestamp(data['time']);
              } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                lastMessage = "Keine Nachrichten";
              }

              // Bauen desChat-Objekt dynamisch zusammen
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

              return _buildChatTile(liveChat, isLive: true, textColor: textColor);
            },
          );
        }

        // --- FALL 2: Alle anderen Chats (Statisch / Bot) ---
        // index - 1, weil der erste Platz vom Live Chat belegt ist
        final chat = _staticChats[index - 1];
        return _buildChatTile(chat, isLive: false, textColor: textColor);
      },
    );
  }

  // Hilfsfunktion zum Bauen einer einzelnen Chat-Kachel
  Widget _buildChatTile(Map<String, dynamic> chat, {required bool isLive, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          if (chat['name'] == "Support Bot") {
             Navigator.push(
               context, 
               MaterialPageRoute(builder: (context) => SupportBotScreen())
             );
          } else if (isLive) { // Wenn es der Live Chat ist
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
            // --- AVATAR / ICON ---
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
            
            // --- MITTE: NAME & NACHRICHT ---
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
                    chat['message'], // Hier steht jetzt die echte letzte Nachricht!
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: (chat['unread'] as int) > 0 
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87) 
                          : Colors.grey,
                      fontWeight: (chat['unread'] as int) > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            
            // --- RECHTS: ZEIT & UNGELESEN ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                // Nur anzeigen, wenn > 0
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