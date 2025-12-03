import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme_notifier.dart';

class ChatTheme {
  // 1. ÄNDERUNG: Standardfarbe ist jetzt Hellgrau (Erster Eintrag der Liste)
  static Color myBubbleColor = Colors.blue[800]!;
  static Color backgroundColor = const Color(0xFFEEEEEE); 

  // --- Farben Speichern & Laden (wie bisher) ---
  static Future<void> saveTheme(Color bubble, Color bg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bubble_color', bubble.value);
    await prefs.setInt('bg_color', bg.value);
    
    myBubbleColor = bubble;
    backgroundColor = bg;
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? bubbleVal = prefs.getInt('bubble_color');
    int? bgVal = prefs.getInt('bg_color');

    if (bubbleVal != null) myBubbleColor = Color(bubbleVal);
    if (bgVal != null) backgroundColor = Color(bgVal);
  }

  // --- 2. ÄNDERUNG: Dark Mode Speichern ---
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    // Wir speichern "ThemeMode.dark" oder "ThemeMode.light" als String
    await prefs.setString('theme_mode', mode.toString());
  }

  // --- 2. ÄNDERUNG: Dark Mode Laden ---
  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String? modeString = prefs.getString('theme_mode');

    // Wenn ein Wert gespeichert ist, setzen wir den Notifier
    if (modeString != null) {
      if (modeString == ThemeMode.dark.toString()) {
        themeNotifier.value = ThemeMode.dark;
      } else {
        themeNotifier.value = ThemeMode.light;
      }
    }
  }
} 