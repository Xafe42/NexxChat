import 'package:flutter/material.dart';

import '../theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wir nutzen ValueListenableBuilder hier auch, damit der Switch sich optisch sofort umlegt
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDarkMode = currentMode == ThemeMode.dark;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Einstellungen",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // App Appearance
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    value: isDarkMode,
                    onChanged: (val) {
                      themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text("Personalisierung"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Platzhalter für Personalisierung
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Personalisierung kommt bald...")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}