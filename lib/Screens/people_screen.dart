import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme_notifier.dart';
import '../core/services/chat_service.dart';
import 'private_chat_screen.dart';
import 'welcome_screens.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String currentEmail = user!.email!;
    final String currentUid = user.uid;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final bool isDark = mode == ThemeMode.dark;
        final Color textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(

          // ============================
          //   FLOATING ACTION BUTTON
          // ============================
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Add Action 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Coming soon…")),
              );
            },
            backgroundColor: isDark ? Colors.grey[800] : Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
          ),

          body: Column(
            children: [

              // ============================
              //            HEADER
              // ============================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Text(
                      "People",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        _circleButton(
                          icon: Icons.search,
                          iconColor: textColor,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ============================
              //         USERS LIST
              // ============================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No users found",
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }

                    final users = snapshot.data!.docs.where((doc) {
                      return doc["email"] != currentEmail;
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "No other users available",
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final data = users[index];
                        final name = data["fullName"] ?? "Unknown";
                        final email = data["email"];
                        final pic = data["profilePic"] ?? "";
                        final otherUid = data["uid"];

                        return InkWell(
                          onTap: () async {
                            final chat = ChatService();

                            final convId = await chat.createOrGetDirectChat(
                              currentUid: currentUid,
                              otherUid: otherUid,
                            );

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrivateChatScreen(
                                  conversationId: convId,
                                  title: name,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      Colors.orange.withOpacity(0.2),
                                  backgroundImage:
                                      pic.isNotEmpty ? NetworkImage(pic) : null,
                                  child: pic.isEmpty
                                      ? Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// SMALL CIRCLE BUTTON
  Widget _circleButton({
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}