import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  List<String> selectedMembers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Column(
        children: [
          // Group name
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Select Members", style: TextStyle(fontSize: 18)),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final user = docs[index];
                    final uid = user.id;
                    final email = user["email"];
                    final name = user["fullName"];

                    final isSelected = selectedMembers.contains(uid);

                    return ListTile(
                      leading: CircleAvatar(child: Text(name[0])),
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              selectedMembers.add(uid);
                            } else {
                              selectedMembers.remove(uid);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: _createGroup,
            child: const Text("Create"),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Always include current user
    if (!selectedMembers.contains(uid)) {
      selectedMembers.add(uid);
    }

    await FirebaseFirestore.instance.collection("conversations").add({
      "name": groupNameController.text.trim(),
      "isGroup": true,
      "createdAt": DateTime.now(),
      "createdBy": uid,
      "members": selectedMembers,
      "lastMessage": "",
      "lastMessageTime": DateTime.now(),
    });

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }
}