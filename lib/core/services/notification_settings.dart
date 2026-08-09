import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  static const _keySound = "notif_sound";

  static final ValueNotifier<bool> soundEnabled =
      ValueNotifier(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled.value = prefs.getBool(_keySound) ?? true;
  }

  static Future<void> setSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, value);
    soundEnabled.value = value;
  }

  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySound) ?? true;
  }
}