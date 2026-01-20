import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/Screens/welcome_screens.dart';
import 'package:nexxchat_firebase/core/Call_listener.dart';
import 'package:nexxchat_firebase/core/call/call_mini_overlay.dart';
import 'package:nexxchat_firebase/core/navigation.dart';

import 'core/services/chat_theme.dart';
import 'theme_notifier.dart';
import 'package:provider/provider.dart';
import 'core/call/call_session.dart';
// NEU: Hintergrund-Handler (ganz oben!)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // NEU: Hintergrund-Handling registrieren
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // NEU: Kanal für Android Vibration erstellen
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_messages', 
    'Chat Benachrichtigungen',
    importance: Importance.max, // Max sorgt für das aufpoppende Banner
    enableVibration: true,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await ChatTheme.loadTheme();
  await ChatTheme.loadThemeMode();

  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => CallSession(),
      ),
    ],
    child: MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instanz von Firebase Auth

  MyApp({super.key}); // Konstruktor, übergibt key an die Superklasse

  @override
  Widget build(BuildContext context) {
    // 1. Listener für Dark/Light Mode
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        
        // 2. NEU: Listener für Farbänderungen (reloadNotifier)
        return ValueListenableBuilder<int>(
          valueListenable: reloadNotifier, 
          builder: (context, _, __) {

            // Optional: Passt die System-Leiste unten (Android Buttons) an
            final bool isDark = currentMode == ThemeMode.dark;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              systemNavigationBarColor: isDark ? const Color(0xFF121212) : Colors.white,
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ));

            
return GlobalCallListener(
  child: MaterialApp(
    navigatorKey: globalNavigatorKey,
    title: 'NexxChat',
    debugShowCheckedModeBanner: false,

    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
    ),

    darkTheme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
    ),

    themeMode: currentMode,

    initialRoute: _auth.currentUser != null
        ? ChatHomeScreen.screenRoute
        : WelcomeScreen.screenRoute,

    routes: {
      WelcomeScreen.screenRoute: (_) => const WelcomeScreen(),
      SignInScreen.screenRoute: (_) => const SignInScreen(),
      RegistrationScreen.screenRoute: (_) => const RegistrationScreen(),
      ChatScreen.screenRoute: (_) => const ChatScreen(),
      ChatHomeScreen.screenRoute: (_) => const ChatHomeScreen(),
    },

    builder: (context, child) {
      return Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => child!,
          ),
          OverlayEntry(
            builder: (context) => const CallMiniOverlay(),
          ),
        ],
      );
    },
  ),
);      
          },
        );
      },
    );
  }
}