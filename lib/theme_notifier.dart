import 'package:flutter/material.dart';

// Ein globaler Notifier, um das Theme zu ändern
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);