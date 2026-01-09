import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexxchat_firebase/Screens/registration_screen.dart';
import 'package:nexxchat_firebase/Screens/chat_home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const String screenRoute = 'welcome_screen';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  // ===== LOGIN FUNCTION =====
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      
      Navigator.pushReplacementNamed(
        context,
        ChatHomeScreen.screenRoute,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== TOP BAR =====
            Container(
  height: 56,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  color: const Color(0xFF3B5998),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Image.asset(
        'images/nexxchat.png',
        width: 28,
        height: 28,
      ),
      const SizedBox(width: 8),
      const Text(
        'NexxChat',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),

              // ===== CONTENT =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== TITLE =====
                    const Text(
                      'Welcome to NexxChat!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'NexxChat helps you connect and chat with the people in your life.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== EMAIL =====
                    const Text(
                      'Email address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _inputField(
                      controller: _emailController,
                      obscure: false,
                    ),

                    const SizedBox(height: 12),

                    // ===== PASSWORD =====
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _inputField(
                      controller: _passwordController,
                      obscure: true,
                    ),

                    const SizedBox(height: 12),

                    // ===== LOGIN BUTTON =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 150,
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5998),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ===== FORGOT PASSWORD (NO ACTION) =====
                    const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B5998),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== REGISTER =====
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RegistrationScreen.screenRoute,
                        );
                      },
                      child: const Text(
                        'Need a NexxChat account? Sign up here.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF3B5998),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== LANGUAGE SECTION =====
                    const Divider(color: Colors.black26),
                    const SizedBox(height: 10),

                    const Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Fake dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'English (UK)',
                            style: TextStyle(fontSize: 14),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Change language button
                    Container(
                      width: 160,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B5998),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Change language',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Help',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B5998),
                      ),
                    ),

                    const SizedBox(height: 150),

                    const Text(
                      'NexxChat © 2026 · Mobile site · Touch site',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3B5998),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== INPUT FIELD =====
  Widget _inputField({
    required TextEditingController controller,
    required bool obscure,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }
}