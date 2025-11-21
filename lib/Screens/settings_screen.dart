import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../core/chat_theme.dart';
import 'welcome_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
//                               SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Settings"),
            centerTitle: true,
          ),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 10),

              // ------------------- Appearance -------------------
              _sectionTitle("Appearance"),

              // Dark Mode Tile
              _tile(
                context,
                icon: Icons.dark_mode,
                title: "Dark Mode",
                subtitle: "Switch between light & dark theme",
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    themeNotifier.value =
                        val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),

              // Personalization
              _tile(
                context,
                icon: Icons.color_lens,
                title: "Personalization",
                subtitle: "Theme colors & chat bubbles",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatDesignScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ------------------- Security -------------------
              _sectionTitle("Security"),

              _tile(
                context,
                icon: Icons.lock,
                title: "Privacy & Security",
                subtitle: "Password, activity & permissions",
                onTap: () {},
              ),

              const SizedBox(height: 20),

              // ------------------- Notifications -------------------
              _sectionTitle("Notifications"),

              _tile(
                context,
                icon: Icons.notifications,
                title: "Notification Settings",
                subtitle: "Manage chat & system alerts",
                onTap: () {},
              ),

              const SizedBox(height: 20),

              // ------------------- About -------------------
              _sectionTitle("About"),

              _tile(
                context,
                icon: Icons.info,
                title: "About NexChat",
                subtitle: "Version 1.0.0 – All rights reserved",
                onTap: () {},
              ),

              const SizedBox(height: 30),

              // ------------------- LOGOUT -------------------
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      WelcomeScreen.screenRoute,
                      (_) => false,
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

  // ---------------- UI HELPERS ----------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Function()? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
//                         CHAT DESIGN CUSTOMIZER SCREEN
// ============================================================================

class ChatDesignScreen extends StatefulWidget {
  const ChatDesignScreen({super.key});

  @override
  State<ChatDesignScreen> createState() => _ChatDesignScreenState();
}

class _ChatDesignScreenState extends State<ChatDesignScreen> {
  final List<Color> bubbleColors = [
    Colors.blue[800]!,
    Colors.purple,
    Colors.orange[800]!,
    Colors.green[700]!,
    Colors.redAccent,
    Colors.black87,
    Colors.teal,
    Colors.pink,
  ];

  final List<Color> bgColors = [
    Colors.white,
    const Color(0xFFF5F5F5),
    const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFF3E0),
    const Color(0xFFE8F5E9),
    const Color(0xFF212121),
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    await ChatTheme.loadTheme();
    setState(() {});
  }

  void _save(Color bubble, Color bg) {
    ChatTheme.saveTheme(bubble, bg);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Design saved!"),
        duration: Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Design"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // PREVIEW
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChatTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Other message
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text("How do you like the new design?"),
                  ),
                ),
                const SizedBox(height: 12),

                // Your message
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChatTheme.myBubbleColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Looks great!",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // COLOR PICKER BUBBLES
          const Text("Message Bubble Color",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bubbleColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = bubbleColors[i];
                final selected = ChatTheme.myBubbleColor == c;

                return GestureDetector(
                  onTap: () => _save(c, ChatTheme.backgroundColor),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // BACKGROUND PICKER
          const Text("Chat Background",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bgColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = bgColors[i];
                final selected = ChatTheme.backgroundColor == c;

                return GestureDetector(
                  onTap: () => _save(ChatTheme.myBubbleColor, c),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selected
                        ? Icon(Icons.check,
                            color: c.computeLuminance() < 0.5
                                ? Colors.white
                                : Colors.black)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}