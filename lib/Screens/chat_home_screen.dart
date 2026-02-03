import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/SearchUsersScreen.dart';
import 'package:nexxchat_firebase/Screens/people_screen.dart';
import 'package:nexxchat_firebase/core/services/call_service.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart';

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
  
  // Controller für das Wischen zwischen den Seiten
  late PageController _pageController;

  /// IDs of hidden conversations
  List<String> _hiddenChats = [];

  /// For every hidden chat: when it was hidden (so we know if there's a newer message)
  Map<String, Timestamp?> _hiddenChatTimes = {};

  bool _loadingUserHiddenChats = true;

  // Statische Bots (Behalten ihre eigene Farbe, da sie "Brands" sind)
  final List<Map<String, dynamic>> _staticChats = [];
  final CallService _callService = CallService();

  final Set<String> _handledCallIds = {};
  final bool _incomingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    // Initialisierung des PageControllers
    _pageController = PageController(initialPage: _selectedIndex);
    _loadTheme();
    _loadHiddenChats();
    _saveFcmToken(); // NEU: Adresse des Handys speichern
    _listenIncomingCalls();
  }

  @override
  void dispose() {
    // Controller sauber löschen
    _pageController.dispose();
    super.dispose();
  }

  void _listenIncomingCalls() {
    final uid = currentUser?.uid;
    if (uid == null) return;
  }

  Future<void> _saveFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null && currentUser != null) {
      await _firestore.collection("users").doc(currentUser!.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
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
        _hiddenChats = List<String>.from(data["hiddenChats"] ?? <String>[]);

        final hiddenTimesRaw = data["hiddenChatsTime"] as Map<String, dynamic>?;

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
    // Dark Mode auf Notifier hören (optional)
    setState(() {});
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
    // FIX: Nutzt jetzt die System-Helligkeit statt der statischen Variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX: Nutzt jetzt die System-Hintergrundfarbe (aus main.dart) statt der personalisierten Farbe
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final accentColor = ChatTheme.getBubbleColor();

    if (currentUser == null || _loadingUserHiddenChats) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        // PageView ermöglicht das Wischen nach rechts/links
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            // Aktualisiert den Index der Bottom Bar beim Wischen
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            // SEITE 1: CHATS
            Column(
              children: [
                _buildHeader(textColor, isDark),
                Expanded(
                  child: _buildChatList(textColor, subTextColor, accentColor),
                ),
              ],
            ),
            // SEITE 2: PEOPLE
            const PeopleScreen(),
            // SEITE 3: SETTINGS
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              // FIX: withOpacity -> withValues
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // Animiert die Seite beim Klick auf die Icons
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupportBotScreen(),
                  ),
                );
              },
              backgroundColor: Colors.white,
              elevation: 6,
              child: Icon(
                Icons.smart_toy_rounded, // 🤖 KI icon
                color: ChatTheme.myBubbleColor,
                size: 28,
              ),
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
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // FIX: withOpacity -> withValues
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: textColor, size: 26),
              onPressed: () {
                // Wechselt zur People-Seite
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // FIX: withOpacity -> withValues
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.search_rounded, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                );
              },
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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
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

            if (isHidden) {
              final lastDate = lastMsgTime?.toDate();
              final hiddenDate = hiddenAt?.toDate();

              final hasNewMessage = lastDate != null &&
                  (hiddenDate == null || lastDate.isAfter(hiddenDate));

              if (!hasNewMessage) {
                return const SizedBox.shrink();
              } else {
                _unhideChat(convDoc.id);
              }
            }

            final isGroup = convData['isGroup'] ?? false;
            final lastMsg = convData['lastMessage'] ?? "";
            final timeStr = _formatTimestamp(lastMsgTime);

            if (isGroup) {
              final groupName = convData['name'] ?? "Gruppe";
              final groupPhotoUrl = convData['groupPhotoURL'];
              final storedColor = convData['color'] != null
                  ? Color(convData['color'])
                  : accentColor;

              final chatMap = {
                "name": groupName,
                "message": lastMsg,
                "time": timeStr,
                "avatar": groupPhotoUrl,
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
                  final photoUrl = userData?['photoURL'];

                  final chatMap = {
                    "name": name,
                    "message": lastMsg,
                    "time": timeStr,
                    "avatarUrl": photoUrl,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (chat['name'] == "Support Bot") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportBotScreen()),
            );
          } else if (chat['name'] == "AI Image Generator") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImageBotScreen()),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          child: Row(
            children: [
              // Avatar
              SizedBox(
                width: 52,
                height: 52,
                child: ClipOval(
                  child: Container(
                    color: (chat['color'] as Color),
                    child: _buildAvatarContent(chat),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Name + Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w500,
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
                            ),
                          ),
                        ),
                        if ((chat['unread'] as int) > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
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
    );
  }

  Widget _buildAvatarContent(Map<String, dynamic> chat) {
    // GROUP IMAGE (from Firebase)
    final groupAvatar = chat['avatar'];
    if (groupAvatar != null &&
        groupAvatar.toString().isNotEmpty &&
        groupAvatar.toString().startsWith('http')) {
      return Image.network(
        groupAvatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitial(chat),
      );
    }

    //  USER PROFILE IMAGE
    final avatarUrl = chat['avatarUrl'];
    if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitial(chat),
      );
    }

    //  ICON (groups without image / bots)
    if (chat['icon'] != null) {
      return Icon(
        chat['icon'] as IconData,
        color: Colors.white,
        size: 28,
      );
    }

    //  FALLBACK LETTER
    return _buildInitial(chat);
  }

  Widget _buildInitial(Map<String, dynamic> chat) {
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