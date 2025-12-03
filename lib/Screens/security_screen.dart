import 'package:cloud_firestore/cloud_firestore.dart';
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

  // -------------------------------------------------------
  // DELETE HELPERS
  // -------------------------------------------------------

  Future<void> deleteUserFromFirestore(String uid) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).delete();
  }

  Future<void> removeUserFromAllContacts(String uid) async {
    final users = await FirebaseFirestore.instance.collection("users").get();

    for (var doc in users.docs) {
      await doc.reference.update({
        "groups": FieldValue.arrayRemove([uid]),
      });
    }
  }

  // Delete chats + messages if exist
  Future<void> deleteUserChats(String uid) async {
    final chats = await FirebaseFirestore.instance
        .collection("chats")
        .where("members", arrayContains: uid)
        .get();

    for (var chat in chats.docs) {
      // delete subcollection messages if exist
      final messages = await chat.reference.collection("messages").get();
      for (var msg in messages.docs) {
        await msg.reference.delete();
      }

      await chat.reference.delete();
    }
  }

  // -------------------------------------------------------
  // CHANGE PASSWORD
  // -------------------------------------------------------
  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPassController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -------------------------------------------------------
  // DELETE ACCOUNT
  // -------------------------------------------------------
  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String confirmPass = "";

    final deleteConfirmed = await showDialog(
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete")),
          ],
        );
      },
    );

    if (deleteConfirmed != true || confirmPass.isEmpty) return;

    try {
      // 1) Reauthenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: confirmPass,
      );

      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;

      // 2) Clean Firestore
      await deleteUserChats(uid);
      await removeUserFromAllContacts(uid);
      await deleteUserFromFirestore(uid);

      // 3) Delete FirebaseAuth account
      await user.delete();

      // 4) Redirect
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          WelcomeScreen.screenRoute,
          (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
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
              // Change password
              const Text("Change Password",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

              // Delete account
              const Text("Delete Account",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                "This action cannot be undone. Your messages and account data will be permanently deleted.",
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _deleteAccount,
                child: const Text("Delete my account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}