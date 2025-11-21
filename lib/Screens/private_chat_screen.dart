import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../core/services/chat_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _chatService = ChatService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  User? _user;
  bool _sending = false;
  bool _lastTypingState = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _setTyping(false);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _setTyping(bool isTyping) async {
    if (_user == null) return;
    if (isTyping == _lastTypingState) return;

    _lastTypingState = isTyping;

    await _db.collection('conversations').doc(widget.conversationId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([_user!.uid])
          : FieldValue.arrayRemove([_user!.uid]),
    });
  }

  void _onTextChanged(String value) {
    _setTyping(value.trim().isNotEmpty);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        text: text,
        senderUid: _user!.uid,
        senderEmail: _user!.email ?? '',
      );

      _ctrl.clear();
      _setTyping(false);

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage(File file) async {
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';

    final ref = FirebaseStorage.instance.ref().child('chat_images/$filename');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _chatService.sendImageMessage(
      conversationId: widget.conversationId,
      url: url,
      senderUid: _user!.uid,
    );
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    await _sendImage(File(img.path));
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    await _sendImage(File(img.path));
  }

  void _openAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple,
                    child: IconButton(
                      icon: const Icon(Icons.image, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickFromGallery();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Gallery")
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Camera")
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    return DateFormat('HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleMe = isDark ? Colors.teal[600]! : const Color(0xFF075E54);
    final bubbleOther = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFF075E54),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                widget.title[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.messagesStream(widget.conversationId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = docs[i].data();
                    final isMe = msg['senderId'] == _user!.uid;
                    final type = msg["type"] ?? "text";

                    if (type == "image") {
                      return _ImageBubble(
                        imageUrl: msg["content"],
                        time: _formatTime(msg["timestamp"]),
                        isMe: isMe,
                      );
                    }

                    return _MessageBubble(
                      text: msg["content"],
                      time: _formatTime(msg["timestamp"]),
                      isMe: isMe,
                      bubbleColor: isMe ? bubbleMe : bubbleOther,
                      textColor: isMe ? Colors.white : Colors.black,
                    );
                  },
                );
              },
            ),
          ),

          /// 🔥🔥🔥 NEW: typing indicator under messages
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection("conversations")
                .doc(widget.conversationId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.data() == null) {
                return const SizedBox(height: 0);
              }

              final data = snap.data!.data()!;
              final typingUsers =
                  List<String>.from(data["typingUsers"] ?? []);
              final members =
                  List<String>.from(data["members"] ?? []);

              final otherUid =
                  members.firstWhere((m) => m != _user!.uid, orElse: () => "");

              final isTyping =
                  otherUid.isNotEmpty && typingUsers.contains(otherUid);

              if (!isTyping) return const SizedBox(height: 0);

              return Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 6),
                child: Text(
                  "typing…",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),

          _buildInput(isDark),
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              onPressed: _openAttachmentMenu,
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: "Nachricht senden ",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            CircleAvatar(
              backgroundColor: const Color(0xFF075E54),
              child: IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ))
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final String time;
  final bool isMe;

  const _ImageBubble({
    required this.imageUrl,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                width: 220,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final Color bubbleColor;
  final Color textColor;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.bubbleColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 12 : 0),
            topRight: Radius.circular(isMe ? 0 : 12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(color: textColor, fontSize: 17)),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}