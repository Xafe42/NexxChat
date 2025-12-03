import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart'; // Import Übersicht
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
  setState(() => showSpinner = true);

  try {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      ChatHomeScreen.screenRoute,
      (route) => false,
    );

  } on FirebaseAuthException catch (e) {
    if (e.code == "user-not-found") {
      _showError("Dieses E-Mail-Konto existiert nicht.");
    } else if (e.code == "wrong-password") {
      _showError("Falsches Passwort.");
    } else if (e.code == "invalid-email") {
      _showError("Ungültige E-Mail-Adresse.");
    } else {
      _showError("Fehler: ${e.message}");
    }
  } catch (e) {
    _showError("Unbekannter Fehler ist aufgetreten.");
  } finally {
    if (mounted) setState(() => showSpinner = false);
  }
}

  @override
  Widget build(BuildContext context) {
    // ... (Dein UI Code bleibt hier unverändert) ...
    return Scaffold(
      backgroundColor: Colors.white, // Hintergrundfarbe
      body: ModalProgressHUD(
        inAsyncCall: showSpinner, // Zeigt Spinner während Ladezeit
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
          ), // Abstand zu den Seiten
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Vertikale Zentrierung
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Widgets füllen die Breite
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
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
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

}