import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../core/services/chat_service.dart';
import 'private_chat_screen.dart';
import '../Screens/SearchUsersScreen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _auth = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser!.uid;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,

      // FAB für neue Chats
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? Colors.grey[800] : Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
          );
        },
      ),

      body: Column(
        children: [
          // HEADER -------------------------------------------------------------
          Padding(
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
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.search, color: textColor),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // SUCHE -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v.trim().toLowerCase();
                }),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Search…",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // LISTE DER CHATS ---------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, convSnap) {
                if (!convSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final convs = convSnap.data!.docs.where((c) {
                  final members = List<String>.from(c["members"]);
                  return members.contains(currentUid);
                }).toList();

                if (convs.isEmpty) {
                  return Center(
                    child: Text(
                      "No chats yet",
                      style: TextStyle(fontSize: 17, color: textColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: convs.length,
                  itemBuilder: (context, i) {
                    final conv = convs[i];
                    final members = List<String>.from(conv['members']);
                    final otherUid = members.firstWhere((m) => m != currentUid);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUid)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const SizedBox();
                        }

                        final data = userSnap.data!;
                        final fullName = data['fullName'];
                        final profilePic = data['profilePic'];
                        final lastMsg = conv['lastMessage'] ?? '';
                        final lastTime = conv['lastMessageTime'];

                        if (_search.isNotEmpty &&
                            !fullName.toLowerCase().contains(_search)) {
                          return const SizedBox();
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrivateChatScreen(
                                  conversationId: conv.id,
                                  title: fullName,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                // AVATAR ------------------------------------------------
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: profilePic != ''
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic == ''
                                      ? Text(
                                          fullName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                  backgroundColor: Colors.teal,
                                ),

                                const SizedBox(width: 14),

                                // NAME + LAST MESSAGE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMsg,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // TIME
                                if (lastTime != null)
                                  Text(
                                    _formatTime(lastTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}