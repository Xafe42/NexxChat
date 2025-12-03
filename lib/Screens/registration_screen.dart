import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart'; // Import Übersicht
import 'package:nexxchat_firebase/widgets/my_button.dart';

class RegistrationScreen extends StatefulWidget {
  static const String screenRoute = 'register_screen'; // Route für Navigator
  const RegistrationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationScreenState createState() => _RegistrationScreenState(); // Erstellt den State
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance; // Firebase Auth Instanz
  late String email; // Eingabe für E-Mail
  late String password; // Eingabe für Passwort
  bool showSpinner = false; // Ladeindikator

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
                onChanged: (value) {
                  email = value;
                }, // Email speichern
                decoration: InputDecoration(
                  hintText: 'Enter your Email', // Platzhalter
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              SizedBox(height: 8), // Abstand
              TextField(
                obscureText: true, // Passwort ausblenden
                textAlign: TextAlign.center,
                onChanged: (value) {
                  password = value;
                }, // Passwort speichern
                decoration: InputDecoration(
                  hintText: 'Enter your password', // Platzhalter
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              SizedBox(height: 10), // Abstand
              MyButton(
                color: Colors.blue[800]!, // Buttonfarbe
                titel: 'Register', // Buttontext
               onPressed: () async {
  setState(() => showSpinner = true);

  try {
    UserCredential userCred =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userCred.user!.uid)
        .set({
      "uid": userCred.user!.uid,
      "email": email.trim(),
      "fullName": email.split('@')[0],
      "profilePic": "",
      "groups": [],
    });

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      ChatHomeScreen.screenRoute,
      (route) => false,
    );

  } on FirebaseAuthException catch (e) {

    if (e.code == "email-already-in-use") {
      _showError("Diese E-Mail wird bereits verwendet!");
    } else if (e.code == "invalid-email") {
      _showError("Ungültige E-Mail-Adresse.");
    } else if (e.code == "weak-password") {
      _showError("Passwort ist zu schwach (min. 6 Zeichen).");
    } else {
      _showError("Fehler: ${e.message}");
    }

  } catch (e) {
    _showError("Unbekannter Fehler beim Registrieren.");
  } finally {
    setState(() => showSpinner = false);
  }
},
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