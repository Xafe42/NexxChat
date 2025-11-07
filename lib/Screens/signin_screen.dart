import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexxchat_firebase/Screens/chat_screen.dart';
import 'package:nexxchat_firebase/widgets/my_button.dart';

class SignInScreen extends StatefulWidget {
  static const String screenRoute = 'signin_screen'; // Route für Navigator
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState(); // Erstellt den State
}

class SignInScreenState extends State<SignInScreen> {
  final _auth = FirebaseAuth.instance; // Firebase Auth Instanz
  String email = ''; // Eingabe für E-Mail
  String password = ''; // Eingabe für Passwort
  bool showSpinner = false; // Ladeindikator

  // Methode für Anmeldung
  Future<void> _signIn() async {
    setState(() {
      showSpinner = true; // Spinner anzeigen
    });

    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return; // Prüft, ob Widget noch existiert

      if (user.user != null) {
        Navigator.pushNamed(context, ChatScreen.screenRoute); // Weiterleitung zum Chat
      }
    } catch (e) {
      debugPrint('Fehler beim Anmelden: $e'); // Fehlerausgabe
    } finally {
      if (mounted) {
        setState(() {
          showSpinner = false; // Spinner ausblenden
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Hintergrundfarbe
      body: ModalProgressHUD(
        inAsyncCall: showSpinner, // Zeigt Spinner während Ladezeit
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // Abstand zu den Seiten
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertikale Zentrierung
            crossAxisAlignment: CrossAxisAlignment.stretch, // Widgets füllen die Breite
            children: [
              SizedBox(
                height: 180.0,
                child: Image.asset('images/nexxchat.png'), // Logo anzeigen
              ),
              const SizedBox(height: 50.0), // Abstand
              TextField(
                keyboardType: TextInputType.emailAddress, // Email-Tastatur
                textAlign: TextAlign.center,
                onChanged: (value) => email = value, // Email speichern
                decoration: InputDecoration(
                  hintText: 'Enter your Email', // Platzhalter
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8), // Abstand
              TextField(
                obscureText: true, // Passwort ausblenden
                textAlign: TextAlign.center,
                onChanged: (value) => password = value, // Passwort speichern
                decoration: InputDecoration(
                  hintText: 'Enter your password', // Platzhalter
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Abstand
              MyButton(
                color: Colors.yellow[900]!, // Buttonfarbe
                titel: 'Sign in', // Buttontext
                onPressed: _signIn, // Anmeldung ausführen
              ),
            ],
          ),
        ),
      ),
    );
  }
}
