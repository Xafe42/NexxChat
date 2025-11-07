import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/signin_screen.dart';
import 'package:nexxchat_firebase/widgets/my_button.dart';

class WelcomeScreen extends StatefulWidget {
  static const String screenRoute = 'welcome_screen';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,      // ← وسط عمودي
                    crossAxisAlignment: CrossAxisAlignment.stretch,   // ← الأزرار تتمد
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: Image.asset(
                              'images/nexxchat.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MessageMe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff2e386b),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      MyButton(
                        color: Colors.yellow[900]!,
                        titel: 'Sign in',
                        onPressed: () {
                          Navigator.pushNamed(context, SignInScreen.screenRoute);
                        },
                      ),
                      const SizedBox(height: 12),
                      MyButton(
                        color: Colors.blue[800]!,
                        titel: 'Register',
                        onPressed: () {
                          Navigator.pushNamed(context, RegistrationScreen.screenRoute);
                        }, 
                      ),
                      const SizedBox(height: 12),
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
