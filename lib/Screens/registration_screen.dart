import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart'; // Import Übersicht
import 'package:nexxchat_firebase/widgets/my_button.dart';

class RegistrationScreen extends StatefulWidget {
  static const String screenRoute = 'register_screen'; // Route für Navigator
  const RegistrationScreen({super.key});

  @override
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
              Container(
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
                  setState(() {
                    showSpinner = true;
                  }); // Spinner anzeigen
                  try {
                    await _auth.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    ); // Registrierungsversuch
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      ChatHomeScreen.screenRoute, // Weiterleitung zur Übersicht
                      (route) => false,
                    ); 
                    setState(() {
                      showSpinner = false;
                    }); // Spinner ausblenden
                  } catch (e) {
                    print(e); // Fehlerausgabe
                    setState(() {
                      showSpinner = false;
                    }); // Spinner ausblenden
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}