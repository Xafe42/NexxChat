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
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== CENTER LOGO =====
Center(
  child: Column(
    children: [
      const SizedBox(height: 30),

      Image.asset(
        'images/nexxchat.png',
        width: 90,
        height: 90,
      ),

      const SizedBox(height: 12),

      const Text(
        'NexxChat',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3B5998),
          letterSpacing: -0.5,
        ),
      ),

      const SizedBox(height: 30),
    ],
  ),
),

              // ===== LOGIN CARD =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to continue to NexxChat',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // EMAIL
                      _modernInput(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        obscure: false,
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      _modernInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),

                      const SizedBox(height: 18),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5998),
                            foregroundColor: Colors.white, 
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ERROR
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),

                      const SizedBox(height: 10),

                      const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3B5998),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // REGISTER
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // FOOTER
              const Text(
                'NexxChat © 2026',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ===== MODERN INPUT =====
  Widget _modernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF2F3F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}