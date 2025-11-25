import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../core/services/chat_service.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_preview.dart';

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
  bool _showScrollBtn = false;

  // Mini-apps state
  bool _isAiPreviewVisible = false;
  bool _isEventPreviewVisible = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;

    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;

      // ListView reverse: true
      final show = _scrollCtrl.offset > 300;
      if (show != _showScrollBtn) {
        setState(() => _showScrollBtn = show);
      }
    });
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
    if (text.isEmpty || _sending || _user == null) return;

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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage(File file) async {
    if (_user == null) return;

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

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
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

  /// mini-apps
  void _openMiniAppsMenu() {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GridView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            children: [
              _MiniAppTile(
                icon: "👋",
                label: "Hello",
                onTap: () {
                  Navigator.pop(context);
                  _sendQuickHello();
                },
              ),
              _MiniAppTile(
                icon: "🖼️",
                label: "Gallery",
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              _MiniAppTile(
                icon: "🎮",
                label: "Tetris",
                onTap: () {
                  Navigator.pop(context);
                  _openTetris();
                },
              ),
              _MiniAppTile(
                icon: "📅",
                label: "Event",
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isEventPreviewVisible = true);
                },
              ),
              _MiniAppTile(
                icon: "🤖",
                label: "AI",
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _isAiPreviewVisible = true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendQuickHello() async {
    if (_user == null) return;

    await _chatService.sendTextMessage(
      conversationId: widget.conversationId,
      text: "👋 Hello!",
      senderUid: _user!.uid,
      senderEmail: _user!.email ?? '',
    );

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openTetris() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TetrisFullScreenPage(
          onFinish: (score) {
            _sendTetrisScore(score);
          },
        ),
      ),
    );
  }

  Future<void> _sendTetrisScore(int score) async {
    if (_user == null) return;

    await _chatService.sendTextMessage(
      conversationId: widget.conversationId,
      text: "🎮 Tetris Score: $score",
      senderUid: _user!.uid,
      senderEmail: _user!.email ?? '',
    );

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    return DateFormat('HH:mm').format(ts.toDate());
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final justDate = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (justDate == today) return 'Today';
    if (justDate == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleMe = isDark ? Colors.teal[600]! : const Color(0xFF075E54);
    final bubbleOther = isDark ? const Color(0xFF262D31) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFF075E54),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '?',
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _chatService.messagesStream(widget.conversationId),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Say hi 👋',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      itemCount: docs.length + 2, // banner + first date
                      itemBuilder: (_, index) {
                        // index == docs.length + 1 → banner
                        if (index == docs.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 4,
                              left: 24,
                              right: 24,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDark
                                    ? const Color.fromARGB(200, 24, 34, 40)
                                    : const Color.fromARGB(148, 248, 236, 130),
                              ),
                              child: Text(
                                '🔒 Messages are end-to-end encrypted. No one outside this chat can read them.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.yellow[200]
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        
                        if (index == docs.length) {
                          final msgData = docs.last.data();
                          final ts = msgData['timestamp'] as Timestamp?;
                          final dt = ts?.toDate() ?? DateTime.now();
                          return _DateChip(label: _formatDateLabel(dt));
                        }

                        final msgIndex = index;
                        final msg = docs[msgIndex].data();
                        final isMe = msg['senderId'] == _user?.uid;
                        final type = msg['type'] ?? 'text';
                        final ts = msg['timestamp'] as Timestamp?;
                        final dt = ts?.toDate() ?? DateTime.now();
                        final time = _formatTime(ts);

                        bool showDateChip = false;
                        if (msgIndex < docs.length - 1) {
                          final nextMsg = docs[msgIndex + 1].data();
                          final nextTs = nextMsg['timestamp'] as Timestamp?;
                          final nextDt =
                              nextTs?.toDate() ?? DateTime.now();

                          final d1 = DateTime(dt.year, dt.month, dt.day);
                          final d2 =
                              DateTime(nextDt.year, nextDt.month, nextDt.day);
                          if (d1.difference(d2).inDays != 0) {
                            showDateChip = true;
                          }
                        }

                        final bubble = type == 'image'
                            ? _ImageBubble(
                                imageUrl: msg['content'] ?? '',
                                time: time,
                                isMe: isMe,
                              )
                            : _MessageBubble(
                                text: msg['content'] ?? '',
                                time: time,
                                isMe: isMe,
                                bubbleColor: isMe ? bubbleMe : bubbleOther,
                                textColor:
                                    isMe ? Colors.white : Colors.black,
                              );

                        if (!showDateChip) return bubble;

                        return Column(
                          children: [
                            _DateChip(label: _formatDateLabel(dt)),
                            bubble,
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // typing indicator
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
                  final members = List<String>.from(data["members"] ?? []);

                  final me = _user?.uid;
                  final otherUid =
                      members.firstWhere((m) => m != me, orElse: () => "");

                  final isTyping =
                      otherUid.isNotEmpty && typingUsers.contains(otherUid);

                  if (!isTyping) return const SizedBox(height: 0);

                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 18, bottom: 4, top: 2),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          "typing…",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              _buildInput(isDark),
            ],
          ),

          // AI Preview
          if (_isAiPreviewVisible)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: AiPreview(
                onCancel: () =>
                    setState(() => _isAiPreviewVisible = false),
                onSend: (prompt, response) async {
                  if (_user != null) {
                    await _chatService.sendTextMessage(
                      conversationId: widget.conversationId,
                      text: "🤖 $response",
                      senderUid: _user!.uid,
                      senderEmail: _user!.email ?? '',
                    );
                  }
                  if (mounted) {
                    setState(() => _isAiPreviewVisible = false);
                  }
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),

          // Event Preview
          if (_isEventPreviewVisible)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: EventPreview(
                onCancel: () =>
                    setState(() => _isEventPreviewVisible = false),
                onSend: (form) async {
                  
                  final payload = EventApp.buildPayload(form);
                  await FirebaseFirestore.instance
                      .collection("events")
                      .add({
                    ...payload,
                    "creator": _user?.email,
                  });

                  
                  if (_user != null) {
                    await _chatService.sendTextMessage(
                      conversationId: widget.conversationId,
                      text: "📅 New event created",
                      senderUid: _user!.uid,
                      senderEmail: _user!.email ?? '',
                    );
                  }

                  if (mounted) {
                    setState(() => _isEventPreviewVisible = false);
                  }
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),

          if (_showScrollBtn)
            Positioned(
              right: 12,
              bottom: 90,
              child: FloatingActionButton(
                mini: true,
                backgroundColor:
                    isDark ? Colors.grey[800] : const Color(0xFF075E54),
                onPressed: () {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: const Icon(Icons.arrow_downward, size: 20),
              ),
            ),
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
            // 📎 attach
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              onPressed: _openAttachmentMenu,
            ),

            // ⚡ mini-apps
            IconButton(
              icon: Icon(
                Icons.flash_on,
                color: isDark ? Colors.yellow[700] : Colors.orange,
              ),
              onPressed: _openMiniAppsMenu,
            ),

            // Text field
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
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Nachricht senden",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Send
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
                        ),
                      )
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

class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromARGB(200, 24, 34, 40)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                width: 230,
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 17),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                // ignore: deprecated_member_use
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


class _MiniAppTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAppTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isDark
                ? const Color(0xFF303030)
                : const Color.fromARGB(255, 255, 243, 224),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}