import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/people_screen.dart';

import '../core/services/chat_theme.dart';
import 'call_screen.dart';
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

  /// IDs of hidden conversations
  List<String> _hiddenChats = [];

  /// For every hidden chat: when it was hidden (so we know if there's a newer message)
  Map<String, Timestamp?> _hiddenChatTimes = {};

  bool _loadingUserHiddenChats = true;

  // Statische Bots (Behalten ihre eigene Farbe, da sie "Brands" sind)
  final List<Map<String, dynamic>> _staticChats = [
    {
      "name": "Support Bot",
      "message": "Ich bin bereit für AI Fragen...",
      "time": "Bot",
      "avatar": null,
      "icon": Icons.smart_toy_rounded,
      "isGroup": false,
      "unread": 0,
      "color": Colors.purpleAccent,
    },
    /*
    {
      "name": "AI Image Generator",
      "message": "Lass uns Bilder erstellen!",
      "time": "Tool",
      "avatar": null,
      "icon": Icons.palette_rounded,
      "isGroup": false,
      "unread": 0,
      "color": Colors.pinkAccent,
    },
    */
  ];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadTheme();
    _loadHiddenChats();
  }

  // 🔥 Hide specific conversation + store hide timestamp
  Future<void> _hideChat(String chatId) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection("users").doc(currentUser!.uid).update({
        "hiddenChats": FieldValue.arrayUnion([chatId]),
        // speichere den Zeitpunkt, wann genau diese Konversation versteckt wurde
        "hiddenChatsTime.$chatId": FieldValue.serverTimestamp(),
      });

      setState(() {
        _hiddenChats.add(chatId);
        // local können wir erstmal null lassen – wird beim nächsten _loadHiddenChats
        // oder Snapshot-Refresh korrekt nachgeladen
        _hiddenChatTimes[chatId] = Timestamp.now();
      });
    } catch (e) {
      debugPrint("Error hiding chat: $e");
    }
  }

  // 🔥 Unhide specific conversation (z.B. wenn neue Nachricht nach hide kam)
  Future<void> _unhideChat(String chatId) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection("users").doc(currentUser!.uid).update({
        "hiddenChats": FieldValue.arrayRemove([chatId]),
        "hiddenChatsTime.$chatId": FieldValue.delete(),
      });

      setState(() {
        _hiddenChats.remove(chatId);
        _hiddenChatTimes.remove(chatId);
      });
    } catch (e) {
      debugPrint("Error un-hiding chat: $e");
    }
  }

  // 🔥 Bottom Sheet bei Longpress
  void _showChatOptions(Map<String, dynamic> chat) {
    if (chat['docId'] == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_off, color: Colors.red),
                title: const Text("Konversation ausblenden"),
                onTap: () {
                  Navigator.pop(context);
                  _hideChat(chat['docId']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadHiddenChats() async {
    if (currentUser == null) {
      setState(() => _loadingUserHiddenChats = false);
      return;
    }

    try {
      final userDoc =
          await _firestore.collection("users").doc(currentUser!.uid).get();

      final data = userDoc.data();
      if (data != null) {
        _hiddenChats =
            List<String>.from(data["hiddenChats"] ?? <String>[]);

        final hiddenTimesRaw =
            data["hiddenChatsTime"] as Map<String, dynamic>?;

        _hiddenChatTimes = {};
        if (hiddenTimesRaw != null) {
          hiddenTimesRaw.forEach((key, value) {
            if (value is Timestamp) {
              _hiddenChatTimes[key] = value;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading hidden chats: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingUserHiddenChats = false);
      }
    }
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.day}.${date.month}.";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FB);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    final accentColor = ChatTheme.myBubbleColor;
    if (currentUser == null || _loadingUserHiddenChats) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      Column(
        children: [
          _buildHeader(textColor, isDark),
          Expanded(
            child: _buildChatList(textColor, subTextColor, accentColor),
          ),
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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: accentColor,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Chats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              activeIcon: Icon(Icons.people_alt),
              label: "People",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              backgroundColor: accentColor,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
      child: Row(
        children: [
          Text(
            "Chats",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.search_rounded, color: textColor),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(
    Color textColor,
    Color? subTextColor,
    Color accentColor,
  ) {
    if (currentUser == null) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('conversations')
          .where('members', arrayContains: currentUser!.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
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
                lastMessage = "✨ App Aktivität";
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
              "color": accentColor,
            };
            return _buildChatTile(
              liveChat,
              isLive: true,
              textColor: textColor,
              subTextColor: subTextColor,
            );
          },
        );

        final conversations = snapshot.hasData ? snapshot.data!.docs : [];
        final totalCount = 1 + _staticChats.length + conversations.length;

        return ListView.builder(
          itemCount: totalCount,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            if (index == 0) return globalChatTile;

            if (index <= _staticChats.length) {
              final chat = _staticChats[index - 1];
              return _buildChatTile(
                chat,
                isLive: false,
                textColor: textColor,
                subTextColor: subTextColor,
              );
            }

            final convIndex = index - (1 + _staticChats.length);
            final convDoc = conversations[convIndex];
            final convData = convDoc.data() as Map<String, dynamic>;

            final lastMsgTime = convData['lastMessageTime'] as Timestamp?;
            final isHidden = _hiddenChats.contains(convDoc.id);
            final hiddenAt = _hiddenChatTimes[convDoc.id];

            // ⚙️ Logic:
            // - If chat is hidden AND there is NO newer message after it was hidden -> keep it hidden
            // - If there *is* a new message (lastMessageTime > hiddenAt) -> unhide & show again
            if (isHidden) {
              final lastDate = lastMsgTime?.toDate();
              final hiddenDate = hiddenAt?.toDate();

              final hasNewMessage = lastDate != null &&
                  (hiddenDate == null || lastDate.isAfter(hiddenDate));

              if (!hasNewMessage) {
                // still hidden, no new messages -> don't render
                return const SizedBox.shrink();
              } else {
                // new message after hide -> unhide in background
                _unhideChat(convDoc.id);
                // und weiter unten ganz normal anzeigen
              }
            }

            final isGroup = convData['isGroup'] ?? false;
            final lastMsg = convData['lastMessage'] ?? "";
            final timeStr = _formatTimestamp(lastMsgTime);

            if (isGroup) {
              final groupName = convData['name'] ?? "Gruppe";
              final storedColor = convData['color'] != null
                  ? Color(convData['color'])
                  : accentColor;

              final chatMap = {
                "name": groupName,
                "message": lastMsg,
                "time": timeStr,
                "avatar": null,
                "icon": Icons.groups_rounded,
                "isGroup": true,
                "unread": 0,
                "color": storedColor,
                "docId": convDoc.id,
              };
              return _buildChatTile(
                chatMap,
                isLive: false,
                textColor: textColor,
                subTextColor: subTextColor,
              );
            } else {
              final members = List<String>.from(convData['members']);
              final otherUid = members.firstWhere(
                (id) => id != currentUser!.uid,
                orElse: () => "",
              );

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUid).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final name = userData?['fullName'] ?? "Unbekannt";

                  final chatMap = {
                    "name": name,
                    "message": lastMsg,
                    "time": timeStr,
                    "avatar": null,
                    "icon": null,
                    "isGroup": false,
                    "unread": 0,
                    "color": accentColor,
                    "docId": convDoc.id,
                  };
                  return _buildChatTile(
                    chatMap,
                    isLive: false,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildChatTile(
    Map<String, dynamic> chat, {
    required bool isLive,
    required Color textColor,
    required Color? subTextColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (chat['name'] == "Support Bot") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportBotScreen(),
                ),
              );
            } else if (chat['name'] == "AI Image Generator") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImageBotScreen(),
                ),
              );
            } else if (isLive) {
              Navigator.pushNamed(context, ChatScreen.screenRoute);
            } else if (chat['docId'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivateChatScreen(
                    conversationId: chat['docId'],
                    title: chat['name'],
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (chat['docId'] != null) {
              _showChatOptions(chat);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (chat['color'] as Color).withOpacity(0.8),
                        (chat['color'] as Color),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (chat['color'] as Color).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildAvatarContent(chat),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              chat['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chat['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: subTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['message'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: subTextColor,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if ((chat['unread'] as int) > 0)
                            Container(
                              margin:
                                  const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                chat['unread'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(Map<String, dynamic> chat) {
    if (chat['icon'] != null) {
      return Icon(
        chat['icon'] as IconData,
        color: Colors.white,
        size: 28,
      );
    }
    if (chat['avatar'] != null) {
      return ClipOval(
        child: Image.asset(
          chat['avatar'],
          fit: BoxFit.cover,
        ),
      );
    }
    return Center(
      child: Text(
        (chat['name'] as String).isNotEmpty
            ? (chat['name'] as String)[0].toUpperCase()
            : "?",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}