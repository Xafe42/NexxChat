import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'welcome_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

              /// Appearance
              _sectionTitle("Appearance"),
              _tile(
                context,
                icon: Icons.dark_mode,
                title: "Dark Mode",
                subtitle: "Switch between light & dark theme",
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),

              /// Personalization
              _tile(
                context,
                icon: Icons.color_lens,
                title: "Personalization",
                subtitle: "Theme colors & chat bubbles",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Coming soon...")),
                  );
                },
              ),

              const SizedBox(height: 15),

              /// Security
              _sectionTitle("Security"),
              _tile(
                context,
                icon: Icons.lock,
                title: "Privacy & Security",
                subtitle: "Password, activity & permissions",
                onTap: () {},
              ),

              const SizedBox(height: 15),

              /// Notifications
              _sectionTitle("Notifications"),
              _tile(
                context,
                icon: Icons.notifications,
                title: "Notification Settings",
                subtitle: "Manage chat & system alerts",
                onTap: () {},
              ),

              const SizedBox(height: 15),

              /// About
              _sectionTitle("About"),
              _tile(
                context,
                icon: Icons.info,
                title: "About NexChat",
                subtitle: "Version 1.0.0 – All rights reserved",
                onTap: () {},
              ),

              const SizedBox(height: 25),

              /// Logout
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

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------
  // UI HELPERS
  // ------------------------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
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
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}