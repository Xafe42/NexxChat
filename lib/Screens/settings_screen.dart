import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_theme.dart';
import '../theme_notifier.dart';
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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final bool isDark = mode == ThemeMode.dark;
        final textColor = isDark ? Colors.white : Colors.black;
        final bgColor = Theme.of(context).scaffoldBackgroundColor;
        final accentColor = ChatTheme.myBubbleColor;

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

              // -------- Appearance Section --------
              _sectionTitle("APPEARANCE"),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    accentColor: accentColor,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeColor: accentColor,
                      onChanged: (val) {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: "Personalization",
                    subtitle: "Theme colors & wallpapers",
                    accentColor: accentColor,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDesignScreen()))
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
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    accentColor: accentColor,
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
                    icon: Icons.info_outline,
                    title: "About NexxChat",
                    subtitle: "Version 1.0.0",
                    accentColor: accentColor,
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
                    if(context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, WelcomeScreen.screenRoute, (_) => false);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _circleButton({required IconData icon, required Color iconColor, required bool isDark, required VoidCallback onTap}) {
    return Container(
      width: 45, height: 45,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon, color: iconColor, size: 24), onPressed: onTap),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
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

  const _SettingsTile({
    required this.icon, 
    required this.title, 
    this.subtitle, 
    this.trailing, 
    this.onTap,
    required this.accentColor
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey[600], fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
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
    Colors.blue[800]!, Colors.purple, Colors.orange[800]!, Colors.green[700]!,
    Colors.redAccent, const Color(0xFF2D3436), Colors.teal, const Color(0xFFE84393),
  ];

  final List<Color> bgColors = [
    const Color(0xFFEEEEEE), const Color(0xFFE3F2FD), const Color(0xFFF3E5F5), const Color(0xFFFFF3E0),
    const Color(0xFFE8F5E9), const Color(0xFFECEFF1), const Color(0xFF212121), Colors.black,
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
      const SnackBar(content: Text("Design saved!"), behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text("Chat Design", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
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
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
                    ),
                    child: Text("How do you like the new design?", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ChatTheme.myBubbleColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: ChatTheme.myBubbleColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: const Text("Looks great! 🚀", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // BUBBLE COLORS
          Text("ACCENT COLOR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5)),
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
                      border: selected ? Border.all(color: textColor, width: 3) : null,
                      boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // BACKGROUND COLORS
          Text("BACKGROUND COLOR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5)),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bgColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (_, i) {
                final c = bgColors[i];
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
                      border: Border.all(color: selected ? Colors.blueAccent : Colors.grey.shade300, width: selected ? 3 : 1),
                    ),
                    child: selected ? Icon(Icons.check, color: c.computeLuminance() < 0.5 ? Colors.white : Colors.black) : null,
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