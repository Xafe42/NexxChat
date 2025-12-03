import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screens.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _auth = FirebaseAuth.instance;

  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();

  bool isLoading = false;

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      // ---- Reauthenticate ----
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // ---- Update password ----
      await user.updatePassword(newPassController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String confirmPass = "";

    // Popup to ask for password
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Confirm account deletion"),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: "Enter your password"),
            onChanged: (v) => confirmPass = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmPass.isEmpty) return;

    try {
      // Reauthenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: confirmPass,
      );
      await user.reauthenticateWithCredential(cred);

      // Delete account
      await user.delete();

      // Redirect to welcome screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, WelcomeScreen.screenRoute, (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Security"),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Change Password",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : _changePassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Update Password"),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            const Text(
              "Delete Account",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "This action cannot be undone. Your messages and account data will be permanently deleted.",
              style: TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _deleteAccount,
              child: const Text("Delete my account"),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

}