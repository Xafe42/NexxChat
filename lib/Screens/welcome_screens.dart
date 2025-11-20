import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/core/app_colors.dart';
import 'package:nexxchat_firebase/widgets/my_button.dart';

class WelcomeScreen extends StatefulWidget {
  static const String screenRoute = 'welcome_screen'; // Route für Navigator
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState(); // Erstellt den State
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background , // Hintergrundfarbe des Bildschirms
      body: SafeArea(
        // Schützt Inhalte vor Notch und Systemleisten
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Scrollbar bei kleinen Bildschirmen
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ), // Mindestens Bildschirmhöhe
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ), // Abstand zu den Seiten
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Vertikal zentriert
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Buttons nehmen volle Breite ein
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 180, // Feste Höhe für das Logo
                            child: Image.asset(
                              'images/nexxchat.png', // App-Logo
                              fit:
                                  BoxFit.contain, // Logo proportional skalieren
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ), // Abstand zwischen Logo und Text
                          const Text(
                            'NexxChat', // App-Name
                            textAlign: TextAlign.center, // Zentrierter Text
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textBlue, // Schriftfarbe
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 30,
                      ), // Abstand zwischen Text und Buttons
                      MyButton(
                        color: AppColors.borderdark , // Farbe des Buttons
                        titel: 'Sign in', // Button-Text
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            SignInScreen.screenRoute,
                          ); // Navigiert zum Login
                        },
                      ),
                      const SizedBox(height: 12), // Abstand zwischen Buttons
                      MyButton(
                        color: AppColors.buttonDark , // Farbe des Buttons
                        titel: 'Register', // Button-Text
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            RegistrationScreen.screenRoute,
                          ); // Navigiert zur Registrierung
                        },
                      ),
                      const SizedBox(height: 12), // Abstand am unteren Ende
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
