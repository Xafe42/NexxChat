import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nexxchat_firebase/widgets/full_screen_image_page.dart';

class GroupSettingsSheet extends StatefulWidget {
  final String conversationId;

  const GroupSettingsSheet({
    super.key,
    required this.conversationId,
  });

  @override
  State<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends State<GroupSettingsSheet> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameCtrl;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? Colors.grey[900] : Colors.white;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('conversations')
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const SizedBox(
            height: 300,
            child: Center(child: Text("Gruppe existiert nicht mehr")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final members = List<String>.from(data['members'] ?? []);
        final adminUid = data['admin'];
        final groupName = data['name'] ?? "Gruppe";
        final currentUid = _auth.currentUser?.uid;

        
        if (nameCtrl.text != groupName) {
          nameCtrl.text = groupName;
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      "Gruppen Einstellungen",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    /// GROUP IMAGE
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          final url = data['groupPhotoURL'];
                          if (url != null && url.toString().isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FullScreenImagePage(imageUrl: url),
                              ),
                            );
                          }
                        },
                        onLongPress:
                            currentUid == adminUid ? _showGroupImageActions : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.grey[400],
                              backgroundImage:
                                  data['groupPhotoURL'] != null &&
                                          data['groupPhotoURL']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(data['groupPhotoURL'])
                                      : null,
                              child: (data['groupPhotoURL'] == null ||
                                      data['groupPhotoURL']
                                          .toString()
                                          .isEmpty)
                                  ? const Icon(Icons.groups,
                                      size: 36, color: Colors.white)
                                  : null,
                            ),
                            if (currentUid == adminUid)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  child: _uploadingImage
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt,
                                          size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// GROUP NAME
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Gruppenname",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            final value = nameCtrl.text.trim();
                            if (value.isEmpty) return;

                            await _db
                                .collection('conversations')
                                .doc(widget.conversationId)
                                .update({'name': value});

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Name gespeichert!")),
                              );
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Divider(),

                    /// MEMBERS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Teilnehmer (${members.length})",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () =>
                              _showAddMemberDialog(context, members),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ACTIONS
                    ListTile(
                      leading: const Icon(Icons.exit_to_app,
                          color: Colors.orange),
                      title: const Text("Gruppe verlassen",
                          style: TextStyle(color: Colors.orange)),
                      onTap: () => _leaveGroup(currentUid!, members),
                    ),

                    if (currentUid == adminUid)
                      ListTile(
                        leading: const Icon(Icons.delete_forever,
                            color: Colors.red),
                        title: const Text("Gruppe löschen",
                            style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteGroup(context),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // IMAGE ACTIONS 
  void _showGroupImageActions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galerie"),
              onTap: () {
                Navigator.pop(context);
                _pickGroupImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickGroupImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Bild entfernen",
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _db
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .update({'groupPhotoURL': FieldValue.delete()});
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickGroupImage(ImageSource source) async {
    final XFile? picked =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_avatars/${widget.conversationId}.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _db
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'groupPhotoURL': url});
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showAddMemberDialog(BuildContext context, List<String> currentMembers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? Colors.grey[900] : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Teilnehmer hinzufügen",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final availableUsers = snapshot.data!.docs
                            .where((doc) => !currentMembers.contains(doc.id))
                            .toList();

                        if (availableUsers.isEmpty) {
                          return const Center(
                              child: Text("Keine weiteren Nutzer gefunden"));
                        }

                        return ListView.builder(
                          controller: scrollCtrl,
                          itemCount: availableUsers.length,
                          itemBuilder: (context, index) {
                            final userDoc = availableUsers[index];
                            final userData =
                                userDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.teal,
                                backgroundImage: userData['photoURL'] != null &&
                                        userData['photoURL']
                                            .toString()
                                            .isNotEmpty
                                    ? NetworkImage(userData['photoURL'])
                                    : null,
                                child: (userData['photoURL'] == null ||
                                        userData['photoURL'].toString().isEmpty)
                                    ? Text(
                                        (userData['fullName'] ?? "?")
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(userData['fullName'] ?? "Unbekannt"),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.blue),
                                onPressed: () async {
                                  await _db
                                      .collection('conversations')
                                      .doc(widget.conversationId)
                                      .update({
                                    'members':
                                        FieldValue.arrayUnion([userDoc.id])
                                  });
                                  if (mounted) Navigator.pop(context);
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
          },
        );
      },
    );
  }
  Future<void> _changeGroupPhoto() async {
  final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

  if (picked == null) return;

  setState(() => _uploadingImage = true);

  try {
    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('group_avatars/${widget.conversationId}.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _db.collection('conversations').doc(widget.conversationId).update({
      'groupPhotoURL': url,
    });
  } catch (e) {
    debugPrint("Error uploading group photo: $e");
  } finally {
    if (mounted) setState(() => _uploadingImage = false);
  }
}

  Future<void> _removeMember(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("$name entfernen?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Nein")),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Ja", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('conversations').doc(widget.conversationId).update({
        'members': FieldValue.arrayRemove([uid])
      });
    }
  }

  Future<void> _leaveGroup(String myUid, List<String> members) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Gruppe verlassen?"),
        content: const Text("Du kannst danach keine Nachrichten mehr senden."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Abbrechen")),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Verlassen",
                  style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm == true) {
      if (members.length <= 1) {
        await _db
            .collection('conversations')
            .doc(widget.conversationId)
            .delete();
      } else {
        await _db
            .collection('conversations')
            .doc(widget.conversationId)
            .update({
          'members': FieldValue.arrayRemove([myUid])
        });
      }
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteGroup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Gruppe löschen?"),
        content: const Text("Dies kann nicht rückgängig gemacht werden."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Abbrechen")),
          TextButton(
              onPressed: () async {
                Navigator.pop(c);
                Navigator.pop(context);
                Navigator.pop(context);
                await _db
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .delete();
              },
              child:
                  const Text("Löschen", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
