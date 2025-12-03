import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/Screens/welcome_screens.dart';

// WICHTIG: Importiere ChatTheme (Passe den Pfad an, falls er anders liegt)
import 'core/services/chat_theme.dart';
import 'theme_notifier.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Stellt sicher, dass Flutter-Bindings initialisiert sind, bevor Firebase geladen wird
  await Firebase.initializeApp(); // Initialisiert Firebase
  
  // NEU: Einstellungen laden bevor die App startet
  await ChatTheme.loadTheme();      // Lädt Farben (Hintergrund 0xFFEEEEEE statt Weiß)
  await ChatTheme.loadThemeMode();  // Lädt Dark/Light Mode Einstellung

  runApp(MyApp()); // Startet die App
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instanz von Firebase Auth

  MyApp({super.key}); // Konstruktor, übergibt key an die Superklasse

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'NexxChat', // Titel der App
          debugShowCheckedModeBanner: false, // Entfernt das Debug-Banner
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white, 
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
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
  }
}