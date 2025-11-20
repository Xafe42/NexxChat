import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'settings_screen.dart'; // Import Settings
import 'welcome_screens.dart'; // Für den Logout-Redirect
import 'package:nexxchat_firebase/core/app_colors.dart';

class ChatHomeScreen extends StatefulWidget {
  static const String screenRoute = "chat_home_screen";
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _auth = FirebaseAuth.instance;
  int _selectedIndex = 0; // Für die Bottom Navigation

  // Mock-Daten für das Design (da wir aktuell nur einen echten Chat-Raum haben)
  final List<Map<String, dynamic>> _chats = [
    {
      "name": "Global Community",
      "message": "User123: /tetris score 500",
      "time": "12:30",
      "avatar": "images/nexxchat.png", // Dein Asset
      "isGroup": true,
      "unread": 3,
      "color": AppColors.primaryDark,
    },
    {
      "name": "Event Planung",
      "message": "Wann geht es los?",
      "time": "09:41",
      "avatar": null,
      "isGroup": true,
      "unread": 0,
      "color": AppColors.secondary,
    },
    {
      "name": "Support Bot",
      "message": "Ich bin bereit für AI Fragen...",
      "time": "Gestern",
      "avatar": null,
      "isGroup": false,
      "unread": 1,
      "color": AppColors.secondary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Wir wechseln den Body basierend auf der Auswahl unten
    final List<Widget> pages = [
      Column(
        children: [
           _buildHeader(),
           Expanded(child: _buildChatList()), // Die eigentliche Liste
        ],
      ),
      const Center(child: Text("People Screen (Placeholder)")),
      const SettingsScreen(), // Der neue Einstellungs-Screen (Index 2)
    ];

    return Scaffold(
      // Background wird jetzt vom Theme gesteuert
      
      // Kein klassischer AppBar-Balken, sondern ein Custom Header
      body: SafeArea(
        child: pages[_selectedIndex],
      ),

      // Moderne Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: AppColors.unselectedItemColor,
          showSelectedLabels: false, // Minimalistischer Look
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Passt sich Theme an
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chats"),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "People"),
            // HIER: Anrufe entfernt, Settings ist jetzt das dritte Element
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
          ],
        ),
      ),
      
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          // Hier könnte man einen neuen Chat starten
        },
        backgroundColor: AppColors.backgrounddark, // Harter Kontrast für Modernität
        child: const Icon(Icons.add, color: AppColors.background),
      ) : null, // FAB nur auf der Chat Seite anzeigen
    );
  }

  // 1. Header Bereich
  Widget _buildHeader() {
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
              // Farbe passt sich dem Theme an
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.background : AppColors.backgrounddark,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100], 
                  shape: BoxShape.circle
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              // Logout Button integriert
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.boxColorDark : AppColors.boxColorLight, 
                  shape: BoxShape.circle
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.iconButtonColor),
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
  Widget _buildChatList() {
    return Container(
      // Container Styling entfernt, damit Dark Mode Hintergrund wirkt
      child: ListView.builder(
        itemCount: _chats.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                // WICHTIG: Wir verlinken den ersten Chat mit deinem existierenden ChatScreen
                if (index == 0) {
                  Navigator.pushNamed(context, ChatScreen.screenRoute);
                } else {
                   // Platzhalter für andere Chats
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Dieser Chat ist noch nicht verbunden."))
                   );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (chat['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: chat['avatar'] != null
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(chat['avatar']),
                          )
                        : Center(
                            child: Text(
                              (chat['name'] as String)[0],
                              style: TextStyle(
                                color: chat['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 15),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // Textfarbe passt sich an
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.background : AppColors.backgrounddark,
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
                                ? (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textPrimary) 
                                : Colors.grey,
                            fontWeight: (chat['unread'] as int) > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Zeit & Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['time'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      if ((chat['unread'] as int) > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primarylight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat['unread'].toString(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}