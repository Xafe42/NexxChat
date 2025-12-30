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

import 'core/services/chat_theme.dart';
import 'theme_notifier.dart';

// NEU: Hintergrund-Handler (ganz oben!)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // NEU: Berechtigung aktiv beim User anfragen (Wichtig für Android 13+ Emulatoren!)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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

  runApp(MyApp());
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

            return MaterialApp(
              title: 'NexxChat', // Titel der App
              debugShowCheckedModeBanner: false, // Entfernt das Debug-Banner
              
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.white, 
                // Hier nutzen wir deine gespeicherte Farbe als Seed
                colorScheme: ColorScheme.fromSeed(
                  seedColor: ChatTheme.myBubbleColor, 
                  brightness: Brightness.light
                ),
                // Zwingt den FAB (Button unten), die Farbe sofort zu ändern
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: ChatTheme.myBubbleColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              darkTheme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: ChatTheme.myBubbleColor, 
                  brightness: Brightness.dark
                ),
                // Zwingt den FAB auch im Dark Mode zur Aktualisierung
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: ChatTheme.myBubbleColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              themeMode: currentMode,
              
              // Startbildschirm abhängig davon, ob der Benutzer eingeloggt ist
              initialRoute: _auth.currentUser != null
                  ? ChatHomeScreen.screenRoute // Wenn eingeloggt, zur Übersicht
                  : WelcomeScreen.screenRoute, // Wenn nicht eingeloggt, Willkommensbildschirm
              
              // Definierte Routen für die App
              routes: {
                WelcomeScreen.screenRoute: (context) => const WelcomeScreen(),
                SignInScreen.screenRoute: (context) => const SignInScreen(),
                RegistrationScreen.screenRoute: (context) => const RegistrationScreen(),
                ChatScreen.screenRoute: (context) => const ChatScreen(),
                ChatHomeScreen.screenRoute: (context) => const ChatHomeScreen(), // Route für Übersicht
              },
            );
          },
        );
      },
    );
  }
}