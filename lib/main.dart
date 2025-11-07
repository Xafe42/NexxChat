import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/Screens/welcome_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Stellt sicher, dass Flutter-Bindings initialisiert sind, bevor Firebase geladen wird
  await Firebase.initializeApp(); // Initialisiert Firebase
  runApp(MyApp()); // Startet die App
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instanz von Firebase Auth

  MyApp({super.key}); // Konstruktor, übergibt key an die Superklasse

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessageMe app', // Titel der App
      debugShowCheckedModeBanner: false, // Entfernt das Debug-Banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Hauptfarbe der App
      ),
      // Startbildschirm abhängig davon, ob der Benutzer eingeloggt ist
      initialRoute: _auth.currentUser != null
          ? ChatScreen.screenRoute // Wenn eingeloggt, direkt zum Chat
          : WelcomeScreen.screenRoute, // Wenn nicht eingeloggt, Willkommensbildschirm
      // Definierte Routen für die App
      routes: {
        WelcomeScreen.screenRoute: (context) => const WelcomeScreen(),
        SignInScreen.screenRoute: (context) => const SignInScreen(),
        RegistrationScreen.screenRoute: (context) => const RegistrationScreen(),
        ChatScreen.screenRoute: (context) => const ChatScreen(),
      },
    );
  }
}
