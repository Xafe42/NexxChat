import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    // Prüfen für Dark/Light Mode Farben
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? Colors.grey[900] : Colors.white;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('conversations')
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
              height: 300, child: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists)
          return const SizedBox(
              height: 300,
              child: Center(child: Text("Gruppe existiert nicht mehr")));

        final updatedData = snapshot.data!.data() as Map<String, dynamic>;
        final members = List<String>.from(updatedData['members'] ?? []);
        final adminUid = updatedData['admin'];
        final groupName = updatedData['name'] ?? "Gruppe";
        final currentUid = _auth.currentUser?.uid;

        final nameCtrl = TextEditingController(text: groupName);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            // Container gegen Farbstich
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
                    const Text("Gruppen Einstellungen",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),

                    // --- 1. NAME ÄNDERN ---
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Gruppenname",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isNotEmpty) {
                              await _db
                                  .collection('conversations')
                                  .doc(widget.conversationId)
                                  .update({'name': nameCtrl.text.trim()});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Name gespeichert!")));
                                FocusScope.of(context).unfocus();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- 2. TEILNEHMER LISTE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Teilnehmer (${members.length})",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon:
                              const Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () =>
                              _showAddMemberDialog(context, members),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (members.isNotEmpty)
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('users')
                            .where(FieldPath.documentId, whereIn: members)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData)
                            return const Center(
                                child: CircularProgressIndicator());

                          final userDocs = userSnapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userDocs.length,
                            itemBuilder: (context, index) {
                              final userData = userDocs[index].data()
                                  as Map<String, dynamic>;
                              final uid = userDocs[index].id;
                              final name = userData['fullName'] ?? "Unbekannt";
                              final isAdmin = uid == adminUid;

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.teal,
                                  backgroundImage:
                                      userData['photoURL'] != null &&
                                              userData['photoURL']
                                                  .toString()
                                                  .isNotEmpty
                                          ? NetworkImage(userData['photoURL'])
                                          : null,
                                  child: (userData['photoURL'] == null ||
                                          userData['photoURL']
                                              .toString()
                                              .isEmpty)
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : "?",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                    name + (uid == currentUid ? " (Du)" : "")),
                                subtitle: isAdmin
                                    ? const Text(
                                        "Admin",
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 12),
                                      )
                                    : null,
                                trailing: (currentUid == adminUid &&
                                        uid != currentUid)
                                    ? IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _removeMember(uid, name),
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                    const Divider(),

                    // --- 3. AKTIONEN ---
                    ListTile(
                      leading:
                          const Icon(Icons.exit_to_app, color: Colors.orange),
                      title: const Text("Gruppe verlassen",
                          style: TextStyle(color: Colors.orange)),
                      onTap: () => _leaveGroup(currentUid!, members),
                    ),

                    if (currentUid == adminUid)
                      ListTile(
                        leading:
                            const Icon(Icons.delete_forever, color: Colors.red),
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
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());

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
