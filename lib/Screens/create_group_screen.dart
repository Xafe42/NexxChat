import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/chat_theme.dart';
import 'private_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _groupNameCtrl = TextEditingController();
  final Set<String> _selectedUids = {};

  bool _isCreating = false;
  String _search = '';

  File? _groupImage;
  String? _groupImageUrl;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  /// Pick image
  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  ///  Upload image
  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('group_images')
        .child('$groupId.jpg');

    await ref.putFile(_groupImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _createGroup() async {
    FocusScope.of(context).unfocus();
    final groupName = _groupNameCtrl.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte gib einen Gruppennamen ein!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wähle mindestens einen Teilnehmer aus!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUid = _auth.currentUser!.uid;
      final members = [currentUid, ..._selectedUids];

      final ref = await _firestore.collection('conversations').add({
        'name': groupName,
        'isGroup': true,
        'admin': currentUid,
        'members': members,
        'lastMessage': 'Gruppe erstellt',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser!.email,
        'groupPhotoURL': null,
        'color': ChatTheme.myBubbleColor.toARGB32(),
        'typingUsers': [],
      });

      // Upload image if exists
      if (_groupImage != null) {
        final url = await _uploadGroupImage(ref.id);
        if (url != null) {
          await ref.update({'groupPhotoURL': url});
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PrivateChatScreen(conversationId: ref.id, title: groupName),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final accentColor = ChatTheme.myBubbleColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Neue Gruppe",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Erstellen",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          /// Group image + name
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickGroupImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    backgroundImage:
                        _groupImage != null ? FileImage(_groupImage!) : null,
                    child: _groupImage == null
                        ? Icon(Icons.camera_alt_rounded,
                            color: accentColor, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _groupNameCtrl,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Gruppenname",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: accentColor));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final name =
                      (data['fullName'] ?? '').toString().toLowerCase();

                  if (uid == currentUid) return false;
                  if (_search.isNotEmpty && !name.contains(_search)) return false;
                  return true;
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData =
                        userDoc.data() as Map<String, dynamic>;
                    final fullName = userData['fullName'] ?? "Unbekannt";
                    final photoUrl = (userData['photoURL'] ?? '').toString();
                    final uid = userDoc.id;
                    final isSelected = _selectedUids.contains(uid);

                    return ListTile(
                      onTap: () {
                        setState(() {
                          isSelected
                              ? _selectedUids.remove(uid)
                              : _selectedUids.add(uid);
                        });
                      },
                      leading: CircleAvatar(
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(fullName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(fullName),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            isSelected
                                ? _selectedUids.remove(uid)
                                : _selectedUids.add(uid);
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}