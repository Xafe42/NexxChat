import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatTheme {
  // Standardfarben
  static Color myBubbleColor = Colors.blue[800]!;
  static Color backgroundColor = Colors.white;

  // Speichern
  static Future<void> saveTheme(Color bubble, Color bg) async {
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt('bubble_color', bubble.value);
    // ignore: deprecated_member_use
    await prefs.setInt('bg_color', bg.value);
    
    // Werte lokal update, damit wir nicht neu laden müssen
    myBubbleColor = bubble;
    backgroundColor = bg;
  }

  // Laden
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int? bubbleVal = prefs.getInt('bubble_color');
    int? bgVal = prefs.getInt('bg_color');

    if (bubbleVal != null) myBubbleColor = Color(bubbleVal);
    if (bgVal != null) backgroundColor = Color(bgVal);
  }
}