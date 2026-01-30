import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChatTheme {
  // Chat-Blasenfarbe
  static Color myBubbleColor = Colors.blue[800]!;

  // Hintergrundfarbe
  static Color backgroundColor = const Color(0xFFEEEEEE); 

  // Dark-Mode Status
  static bool isDarkMode = false; 

  //Merkt sich, ob der User den Hintergrund manuell geändert hat
  //verhindert automatisches Ueberschreiben
  static bool userSetBackground = false;

  // Triggert UI-Updates bei Theme-Aenderungen
  static ValueNotifier<int> reloadNotifier = ValueNotifier(0); 

  //Bubble-Farbe zurueckgeben
  static Color getBubbleColor() => myBubbleColor;
  //Hintergrundfarbe zurueckgeben
  static Color getBackgroundColor() => backgroundColor;
  
  //Theme Speichern (USER)
  static Future<void> saveTheme(Color bubble, Color bg) async {
    final prefs = await SharedPreferences.getInstance();

    myBubbleColor = bubble;
    backgroundColor = bg;
   
    userSetBackground = true;
    await prefs.setBool('user_bg', true);
    // .value ist deprecated, wir nutzen jetzt .toARGB32()
    await prefs.setInt('bubble_color', bubble.toARGB32());
    await prefs.setInt('bg_color', bg.toARGB32());
    
    // NEU: Wir triggern den Reload, damit sich auch der FAB sofort aktualisiert
    reloadNotifier.value++;
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    myBubbleColor = Color(prefs.getInt('bubble_color') ?? myBubbleColor.toARGB32());
    backgroundColor = Color(prefs.getInt('bg_color') ?? backgroundColor.toARGB32());
    userSetBackground = prefs.getBool('user_bg') ?? false; 
    reloadNotifier.value++;
  }

  // --- 2. ÄNDERUNG: Dark Mode Speichern ---
  static Future<void> saveThemeMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = darkMode;
    
    await prefs.setBool('dark_mode', darkMode);
    if (!userSetBackground) {
    backgroundColor =
        darkMode ? const Color(0xFF121212) : const Color(0xFFEEEEEE);

    await prefs.setInt('bg_color', backgroundColor.toARGB32());
    }
    reloadNotifier.value++;
  }

  // --- 2. ÄNDERUNG: Dark Mode Laden ---
  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('dark_mode') ?? false;
    reloadNotifier.value++;
  }

  static Future<void> loadAll() async {
  final prefs = await SharedPreferences.getInstance();

  myBubbleColor =
      Color(prefs.getInt('bubble_color') ?? myBubbleColor.toARGB32());
  backgroundColor =
      Color(prefs.getInt('bg_color') ?? backgroundColor.toARGB32());
  userSetBackground = prefs.getBool('user_bg') ?? false;
  isDarkMode = prefs.getBool('dark_mode') ?? false;

  reloadNotifier.value++;
}

  // --- TEXT COLORS ---
  static Color getPrimarytextColor(){
    return isDarkMode ? Colors.white : Colors.black;
  }
  static Color getSecondarytextColor(){
    return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  }
}