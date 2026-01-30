import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/profile_screen.dart';
import 'package:nexxchat_firebase/Screens/security_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart';
import 'welcome_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;

    return ValueListenableBuilder<int>(
      valueListenable: ChatTheme.reloadNotifier,
      builder: (context, _, __) {
        final bool isDark = ChatTheme.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black;
        // Nimmt die Hintergrundfarbe aus der main.dart (weiß oder dunkelgrau)
        final bgColor = ChatTheme.getBackgroundColor();
        final accentColor = ChatTheme.getBubbleColor();

        return Scaffold(
          backgroundColor: bgColor,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Row(
                  children: [
                    Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _circleButton(
                      icon: Icons.search,
                      iconColor: textColor,
                      isDark: isDark,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Search coming soon…")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _profileHeader(isDark),
              // -------- Appearance Section --------
              _sectionTitle("APPEARANCE"),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    accentColor: accentColor,
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeTrackColor: accentColor,
                      onChanged: (val) {
                        ChatTheme.saveThemeMode(val);
                      },
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: "Personalization",
                    subtitle: "Theme colors & wallpapers",
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChatDesignScreen()))
                          .then((_) => _refresh());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // -------- Security Section --------
              _sectionTitle("PRIVACY & SECURITY"),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: "Security",
                    subtitle: "Password, FaceID & 2FA",
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SecurityScreen()),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // -------- Support Section --------
              _sectionTitle("SUPPORT"),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip,
                    title: "Datenschutzerklärung",
                    subtitle: "Privacy Policy",
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () async {
                      final url = Uri.parse(
                        "https://isha1934.github.io/nexxchat-privacy/privacy_policy.html",
                      );
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    },
                  ),
                  // 2. About NexxChat
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: "About NexxChat",
                    subtitle: "Version 1.0.0",
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // -------- Logout --------
              Center(
                child: TextButton(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, WelcomeScreen.screenRoute, (_) => false);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text("Log Out",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileHeader(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final textColor = isDark ? Colors.white : Colors.black;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] ?? user.email?.split('@').first ?? 'User')
            .toString();
        final photoUrl = (data?['photoURL'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: ChatTheme.myBubbleColor,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,  
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton(
      {required IconData icon,
      required Color iconColor,
      required bool isDark,
      required VoidCallback onTap}) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
          icon: Icon(icon, color: iconColor, size: 24), onPressed: onTap),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.2),
      ),
    );
  }
}

// --- Hilfs-Widgets für das Grouped-Design ---

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsGroup({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool isDark;

  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      required this.accentColor,
      required this.isDark,
      });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.black; // dynamisch
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600]; //dynamisch
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accentColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor,)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(color: subtitleColor, fontSize: 13))
          : null,
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.grey),
    );
  }
}

// ----------------------------------------------------------------
// CHAT DESIGN SCREEN (Modernisiert)
// ----------------------------------------------------------------

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
    const Color(0xFF2D3436),
    Colors.teal,
    const Color(0xFFE84393),
  ];

  final List<Color> bgColors = [
    const Color(0xFFEEEEEE),
    const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5),
    const Color(0xFFFFF3E0),
    const Color(0xFFE8F5E9),
    const Color(0xFFECEFF1),
    
  ];
  final List<Color> darkBgColors = [
  Colors.black,               // echtes Schwarz
  const Color(0xFF121212),    // sehr dunkles Grau (Standard-Dark)
  const Color(0xFF1E1E1E),    // leicht helleres Grau
  const Color(0xFF2C2C2C),    // Anthrazit
  const Color(0xFF0D0D0D),    // fast Schwarz
  const Color(0xFF181818),    // dunkles Graphit
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
    // Keine SnackBar mehr
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ChatTheme.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    final List<Color> displayBgColors = isDark 
    ? darkBgColors
    : bgColors;

    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Chat Design",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // PREVIEW BOX (Handy Mockup)
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChatTheme.backgroundColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2), width: 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5)
                        ]),
                    child: Text("How do you like the new design?",
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87)),
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: ChatTheme.myBubbleColor,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: ChatTheme.myBubbleColor
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Text("Looks great! 🚀",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // BUBBLE COLORS
          Text("ACCENT COLOR",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1.5)),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bubbleColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (_, i) {
                final c = bubbleColors[i];
                final selected = ChatTheme.myBubbleColor == c;
                return GestureDetector(
                  onTap: () => _save(c, ChatTheme.backgroundColor),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 55 : 45,
                    height: selected ? 55 : 45,
                    decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: textColor, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // BACKGROUND COLORS
          Text("BACKGROUND COLOR",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1.5)),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayBgColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (_, i) {
                final c = displayBgColors[i];
                final selected = ChatTheme.backgroundColor == c;
                return GestureDetector(
                  onTap: () => _save(ChatTheme.myBubbleColor, c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 55 : 45,
                    height: selected ? 55 : 45,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: selected
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          width: selected ? 3 : 1),
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
