import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// Local Imports (Bitte Pfade anpassen falls nötig)
import 'package:nexxchat_firebase/Screens/call_screen.dart';
import 'package:nexxchat_firebase/Screens/incoming_scheduled_call_screen.dart';
import 'package:nexxchat_firebase/Screens/image_bot_screen.dart';
import 'package:nexxchat_firebase/widgets/call_time_bubble.dart';
import 'package:nexxchat_firebase/widgets/call_time_message_card.dart';
import 'package:nexxchat_firebase/widgets/calltime_preview.dart';
import 'package:path/path.dart' as path;

// Mini-apps & previews
import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../core/services/chat_service.dart';
import '../core/services/chat_theme.dart';
import '../widgets/ai_preview.dart';
import '../widgets/event_preview.dart';
import '../widgets/group_settings_sheet.dart';
import '../widgets/hello_preview.dart';
import '../widgets/reaction_picker.dart';

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _scheduledCallSub;

  final Set<String> _handledScheduledCalls = {};
  User? _user;
  bool _sending = false;
  bool _lastTypingState = false;
  bool _showScrollBtn = false;

  // -------- Mini-apps state --------
  // ignore: unused_field
  String _raw = "";
  ChatCommand? _aktiveCmd;
  bool _isAiPreviewVisible = false;
  bool _isSlashToolbarVisible = false;
  String? otherUserId;
  bool userDeleted = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadTheme();
    _loadOtherUser();
    _listenScheduledCalls();
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;

      final show = _scrollCtrl.offset > 300;
      if (show != _showScrollBtn) {
        setState(() => _showScrollBtn = show);
      }
    });
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _setTyping(false);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _scheduledCallSub?.cancel();
    super.dispose();
  }

  // ---------- Load Other User ----------
  Future<void> _loadOtherUser() async {
    try {
      final convDoc = await _db
          .collection("conversations")
          .doc(widget.conversationId)
          .get();

      if (!convDoc.exists) return;

      final data = convDoc.data()!;
      final isGroup = data['isGroup'] == true;

      if (isGroup) return;

      final members = List<String>.from(data['members'] ?? []);
      final currentUid = _auth.currentUser?.uid;

      if (currentUid == null) return;

      otherUserId =
          members.firstWhere((id) => id != currentUid, orElse: () => "");

      if (otherUserId!.isNotEmpty) {
        final userDoc = await _db.collection("users").doc(otherUserId).get();
        if (!userDoc.exists) {
          if (mounted) setState(() => userDeleted = true);
        }
      }
    } catch (e) {
      debugPrint("Fehler beim Laden des Users: $e");
    }
  }
  // ---------- Send Call ----------

  Future<void> _sendCallSummary(Map<String, dynamic> call) async {
    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'type': 'call',
      'senderId': _user!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'callType': call['type'], // video
      'status': call['status'], // ended / missed
      'duration': call['duration'], // null if missed
    });

    await convRef.update({
      'lastMessage': call['status'] == 'missed'
          ? '📞 Verpasster Videoanruf'
          : '📞 Videoanruf beendet',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Typing indicator ----------

  Future<void> _setTyping(bool isTyping) async {
    if (_user == null) return;
    if (isTyping == _lastTypingState) return;

    _lastTypingState = isTyping;

    try {
      await _db.collection('conversations').doc(widget.conversationId).update({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([_user!.uid])
            : FieldValue.arrayRemove([_user!.uid]),
      });
    } catch (_) {
      // Ignorieren falls Doc nicht existiert
    }
  }

  void _listenScheduledCalls() {
    if (_user == null) return;

    final convRef = _db.collection("conversations").doc(widget.conversationId);

    _scheduledCallSub = convRef
        .collection("messages")
        .where("type", isEqualTo: "calltime")
        .snapshots()
        .listen((snap) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (final doc in snap.docs) {
        final data = doc.data();
        final status = (data["status"] ?? "scheduled") as String;
        final scheduledAt = data["scheduledAt"] as int?;

        if (scheduledAt == null) continue;

        final msgId = doc.id;

        // ما نحبوش نظهرو نفس الكول مرتين
        if (_handledScheduledCalls.contains(msgId)) continue;

        // يظهر فقط إذا: مازال status = scheduled و وقته وصل (مع مارجن صغير)
        final diff = nowMs - scheduledAt;
        final isDue = diff >= 0 && diff < 2 * 60 * 1000; // في آخر دقيقتين

        if (status == "scheduled" && isDue) {
          _handledScheduledCalls.add(msgId);
          _showIncomingScheduledCall(msgId, data);
        }
      }
    });
  }

  void _showIncomingScheduledCall(
      String messageId, Map<String, dynamic> data) async {
    if (!mounted) return;

    final payload = Map<String, dynamic>.from(data["payload"] ?? {});
    final scheduledAtMs = data["scheduledAt"] as int;
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(scheduledAtMs);

    final note = (payload["note"] ?? "") as String? ?? "";
    final convSnapshot =
        await _db.collection("conversations").doc(widget.conversationId).get();

    final convData = convSnapshot.data() as Map<String, dynamic>?;
    final isGroup = convData?["isGroup"] == true;
    final title = isGroup ? (convData?["name"] ?? widget.title) : widget.title;

    // نفتح الشاشة fullscreen
    // نستعمل push وليس replacement باش نرجع للشات بعد
    // مهم: نعمل update للـ status حسب join/decline
    // باش المرة الجاية ما يعاودش يطلع
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingScheduledCallScreen(
          scheduledAt: scheduledAt,
          title: title,
          note: note.isEmpty ? null : note,
          onJoin: () async {
            // نعلم Firestore اللي الكول تتحل
            await _db
                .collection("conversations")
                .doc(widget.conversationId)
                .collection("messages")
                .doc(messageId)
                .update({"status": "accepted"});

            //callID (conversationId)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callID: widget.conversationId,
                  userID: _user!.uid,
                  userName: _user!.email ?? "User",
                ),
              ),
            );
          },
          onDecline: () async {
            await _db
                .collection("conversations")
                .doc(widget.conversationId)
                .collection("messages")
                .doc(messageId)
                .update({"status": "declined"});

            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ---------- Input change (typing + slash commands) ----------

  void _onTextChanged(String value) {
    _raw = value;
    _setTyping(value.trim().isNotEmpty);

    setState(() {
      _aktiveCmd = CommandRouter.detect(value);

      if (value.startsWith("/") && _aktiveCmd == null) {
        _isSlashToolbarVisible = true;
        _isAiPreviewVisible = false;
      } else {
        _isSlashToolbarVisible = false;
      }

      if (_aktiveCmd?.type == "tetris") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openTetris();
        });
      }
      ;
    });
  }

  // ---------- Basic send (text or command) ----------

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _user == null) return;

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;

      if (cmd.type == "hello") {
        await _sendHelloCommand(cmd);
        _resetInput();
        return;
      }
    }

    // Hidden Chat Logik
    await FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .update({
      "hiddenChats": FieldValue.arrayRemove([widget.conversationId])
    });

    if (mounted) setState(() {});
    setState(() => _sending = true);
    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        text: text,
        senderUid: _user!.uid,
        senderEmail: _user!.email ?? '',
      );

      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
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

  // ---------- Special send helpers (mini-apps) ----------

  Future<void> _sendHelloCommand(ChatCommand cmd) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final helloPayload = HelloApp.buildPayload(cmd.data);

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': helloPayload['type'] ?? 'app',
      'content': '',
      'payload': helloPayload['payload'] ?? {},
    });

    await convRef.update({
      'lastMessage': '👋 Hello',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendAiImage(String url) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'ai_image',
      'content': url,
    });

    await convRef.update({
      'lastMessage': '🤖🖼️ KI Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _sendTetrisScore(int score) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'app',
      'content': '',
      'payload': {
        'app': 'tetris',
        'data': {'score': score},
      },
    });

    await convRef.update({
      'lastMessage': '🎮 Tetris Score: $score',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendAiMessage({
    required String prompt,
    required String response,
  }) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'ai',
      'content': '',
      'payload': {
        'prompt': prompt,
        'response': response,
      },
    });

    await convRef.update({
      'lastMessage': '🤖 AI message',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendEventRef(String eventId) async {
    if (_user == null) return;

    final convRef = _db.collection('conversations').doc(widget.conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != _user!.uid, orElse: () => '');

    final msgRef = convRef.collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _user!.uid,
      'receiverId': receiverUid,
      'sender': _user!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': 'event_ref',
      'content': '',
      'eventId': eventId,
    });

    await convRef.update({
      'lastMessage': '📅 Event',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  void _resetInput() {
    setState(() {
      _ctrl.clear();
      _raw = "";
      _aktiveCmd = null;
      _isSlashToolbarVisible = false;
      _isAiPreviewVisible = false;
    });
    _setTyping(false);
  }

  void _openReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ReactionPicker(
          onSelect: (emoji) {
            _toggleReaction(messageId, emoji);
          },
        );
      },
    );
  }

  Future<void> _sendScheduledCall(Map<String, dynamic> data) async {
    if (_user == null) return;

    final date = data["date"] as String;
    final time = data["time"] as String;
    final note = (data["note"] ?? "") as String;

    final scheduledDateTime = DateTime.parse("$date $time:00");

    final convRef = _db.collection("conversations").doc(widget.conversationId);

    final payload = {
      "date": date,
      "time": time,
      "note": note,
    };

    await convRef.collection("messages").add({
      "type": "calltime",
      "senderId": _user!.uid,
      "timestamp": FieldValue.serverTimestamp(),
      "scheduledAt": scheduledDateTime.millisecondsSinceEpoch,
      "status": "scheduled",
      "payload": payload,
    });

    await convRef.update({
      "lastMessage": "📞 Call on $date at $time",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    _resetInput();
  }
  // ---------- Reactions ----------

  Future<void> _toggleReaction(String messageId, String emoji) async {
    if (_user == null) return;

    final msgRef = _db
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(messageId);

    final snap = await msgRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final currentReaction = data['reaction'];

    if (currentReaction == emoji) {
      await msgRef.update({'reaction': FieldValue.delete()});
    } else {
      await msgRef.update({'reaction': emoji});
    }
  }

  // ---------- Images (gallery / camera) ----------

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
    setState(() => _isSlashToolbarVisible = false);
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;
    await _sendImage(File(img.path));
    setState(() => _isSlashToolbarVisible = false);
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

  // ---------- Mini-apps UI helpers ----------

  void _toggleSlashToolbar() {
    setState(() {
      _isSlashToolbarVisible = !_isSlashToolbarVisible;
      if (_isSlashToolbarVisible) _isAiPreviewVisible = false;
    });
  }

  void _openAiPreview() {
    setState(() {
      _isAiPreviewVisible = true;
      _isSlashToolbarVisible = false;
      _aktiveCmd = null;
    });
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

    _resetInput();
  }

  // ---------- Formatting ----------

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

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleMe = ChatTheme.myBubbleColor;
    final bubbleOther = isDark ? const Color(0xFF262D31) : Colors.white;

    // 🔥 Stream für live updates (Titeländerung)
    return StreamBuilder<DocumentSnapshot>(
        stream: _db
            .collection('conversations')
            .doc(widget.conversationId)
            .snapshots(),
        builder: (context, snapshot) {
          String displayTitle = widget.title;
          Map<String, dynamic>? convData;
          bool isGroup = false;

          if (snapshot.hasData && snapshot.data!.data() != null) {
            convData = snapshot.data!.data() as Map<String, dynamic>;
            isGroup = convData['isGroup'] == true;
            if (isGroup) {
              displayTitle = convData['name'] ?? widget.title;
            }
          }

          return Scaffold(
            backgroundColor: ChatTheme.backgroundColor,
            appBar: AppBar(
                backgroundColor:
                    isDark ? Colors.grey[900] : ChatTheme.myBubbleColor,
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
                      child: isGroup
                          ? const Icon(Icons.groups,
                              color: Colors.white, size: 20)
                          : Text(
                              displayTitle.isNotEmpty
                                  ? displayTitle[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        // 🔥 Klick auf den Titel öffnet jetzt das GroupSettingsSheet
                        onTap: (isGroup && convData != null)
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => GroupSettingsSheet(
                                    conversationId: widget.conversationId,
                                  ),
                                );
                              }
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isGroup)
                              const Text("Tippen für Infos",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // 🔵 VIDEO CALL - PRIVATE CHAT
                  if (!isGroup && convData != null && !userDeleted)
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded,
                          color: Colors.white),
                      onPressed: () async {
                        final members =
                            List<String>.from(convData!['members'] ?? []);

                        final otherUserId = members.firstWhere(
                          (m) => m != _user!.uid,
                          orElse: () => "",
                        );

                        if (otherUserId.isEmpty) return;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callID: widget.conversationId,
                              userID: _user!.uid,
                              userName: _user!.email!,
                            ),
                          ),
                        );

                        if (result != null) {
                          await _sendCallSummary(result);
                          setState(() {});
                        }
                      },
                    ),

                  // 🔵 VIDEO CALL - GROUP
                  if (isGroup && convData != null)
                    IconButton(
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      onPressed: () {
                        final callID = widget.conversationId;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              callID: callID,
                              userID: _user!.uid,
                              userName: _user!.email ?? "User",
                            ),
                          ),
                        );
                      },
                    ),
                ]),
            body: Stack(
              children: [
                Column(
                  children: [
                    // -------- Messages list --------
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            _chatService.messagesStream(widget.conversationId),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final docs = snap.data!.docs;

                          if (userDeleted) {
                            return Center(
                              child: Text(
                                "Dieser Benutzer existiert nicht mehr.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

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
                            itemCount: docs.length + 2,
                            itemBuilder: (_, index) {
                              // Top encryption banner
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
                                          ? const Color.fromARGB(
                                              200, 24, 34, 40)
                                          : const Color.fromARGB(
                                              148, 248, 236, 130),
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

                              // First date chip (oldest message)
                              if (index == docs.length) {
                                final msgData = docs.last.data();
                                final ts = (msgData['timestamp'] ??
                                    msgData['time']) as Timestamp?;
                                final dt = ts?.toDate() ?? DateTime.now();
                                return _DateChip(label: _formatDateLabel(dt));
                              }

                              final msgIndex = index;
                              final msg = docs[msgIndex].data();
                              final msgId = docs[msgIndex].id;
                              final senderEmail = msg['sender'] ?? '';
                              final isMe = msg['senderId'] == _user?.uid ||
                                  senderEmail == _user?.email;

                              final type = msg['type'] ?? 'text';
                              final ts = (msg['timestamp'] ?? msg['time'])
                                  as Timestamp?;
                              final dt = ts?.toDate() ?? DateTime.now();
                              final time = _formatTime(ts);

                              // Need date chip before this message?
                              bool showDateChip = false;
                              if (msgIndex < docs.length - 1) {
                                final nextMsg = docs[msgIndex + 1].data();
                                final nextTs = (nextMsg['timestamp'] ??
                                    nextMsg['time']) as Timestamp?;
                                final nextDt =
                                    nextTs?.toDate() ?? DateTime.now();

                                final d1 = DateTime(dt.year, dt.month, dt.day);
                                final d2 = DateTime(
                                    nextDt.year, nextDt.month, nextDt.day);
                                if (d1.difference(d2).inDays != 0) {
                                  showDateChip = true;
                                }
                              }

                              final bubble = _buildMessageBubble(
                                msg: msg,
                                messageId: msgId,
                                isMe: isMe,
                                type: type,
                                time: time,
                                bubbleMe: bubbleMe,
                                bubbleOther: bubbleOther,
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

                    // -------- Typing indicator --------
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

                        final me = _user?.uid;
                        final otherUid = members.firstWhere((m) => m != me,
                            orElse: () => "");

                        final isTyping = otherUid.isNotEmpty &&
                            typingUsers.contains(otherUid);

                        if (!isTyping) return const SizedBox(height: 0);

                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 18,
                            bottom: 4,
                            top: 2,
                          ),
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

                    // -------- Input row (attach + ⚡ mini-apps + text + send) --------
                    _buildInput(isDark),
                  ],
                ),

                // Scroll to bottom FAB
                if (_showScrollBtn)
                  Positioned(
                    right: 12,
                    bottom: 90,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor:
                          isDark ? Colors.grey[800] : ChatTheme.myBubbleColor,
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

                // -------- Mini-apps overlays --------

                // Hello preview
                if (_aktiveCmd?.type == "hello")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: HelloPreview(
                      text: _aktiveCmd!.previewText!,
                      onCancel: _resetInput,
                      onSend: _send,
                    ),
                  ),

                // AI preview
                if (_isAiPreviewVisible)
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: AiPreview(
                      onCancel: () =>
                          setState(() => _isAiPreviewVisible = false),
                      onSend: (prompt, response) async {
                        await _sendAiMessage(
                            prompt: prompt, response: response);
                        setState(() => _isAiPreviewVisible = false);
                      },
                    ),
                  ),
                // CallTime preview
                if (_aktiveCmd?.type == "calltime")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: CallTimePreview(
                      onCancel: _resetInput,
                      onSend: (data) {
                        _sendScheduledCall(data);
                      },
                    ),
                  ),
                // Event preview
                if (_aktiveCmd?.type == "event")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: EventPreview(
                      onCancel: _resetInput,
                      onSend: (form) async {
                        final eventPayload = EventApp.buildPayload(form);
                        final doc = await _db.collection("events").add({
                          ...eventPayload,
                          "creator": _user!.email,
                        });

                        await _sendEventRef(doc.id);
                        _resetInput();
                      },
                    ),
                  ),

                // Slash mini-apps toolbar
                if (_isSlashToolbarVisible) _slashToolbar(),
              ],
            ),
          );
        });
  }

  // ---------- Build one message bubble (text + image + mini-apps) ----------
  Widget _buildMessageBubble({
    required Map<String, dynamic> msg,
    required String messageId,
    required bool isMe,
    required String type,
    required String time,
    required Color bubbleMe,
    required Color bubbleOther,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isMe ? bubbleMe : bubbleOther;
    final textColor =
        isMe ? Colors.white : (isDark ? Colors.white : Colors.black);
    final payload = msg['payload'] as Map<String, dynamic>?;
    final senderEmail = msg['sender'] ?? '';
    final String? reaction = msg['reaction'];
    // ---------- REACTION (ONE PER MESSAGE) ----------

    if (type == 'calltime') {
      final status = msg['status'] ?? 'scheduled';

      if (status != 'scheduled') {
        return const SizedBox.shrink();
      }

      return CallTimeMessageCard(
        payload: msg["payload"] ?? <String, dynamic>{},
        conversationId: widget.conversationId,
        messageId: messageId,
      );
    }
    // ---------- IMAGE ----------
    if (type == 'image') {
      final url = (msg['content'] ?? payload?['url'] ?? '').toString();

      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openReactionPicker(msg['id']),
            child: _ImageBubble(
              imageUrl: url,
              time: time,
              isMe: isMe,
            ),
          ),
          if (reaction != null) _reactionChip(isMe, reaction),
        ],
      );
    }
    // ---------- CALL ----------

    if (type == 'call') {
      final status = msg['status'];
      final duration = msg['duration'];
      // ignore: unused_local_variable
      final callType = msg['callType'];

      String text = "";

      if (status == "missed") {
        text = "📞 Verpasster Videoanruf";
      } else {
        final minutes = (duration / 60).floor();
        final seconds = duration % 60;
        final durText =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        text = "📞 Videoanruf beendet – Dauer: $durText";
      }

      return _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        textColor: textColor,
        time: time,
        onLongPress: () => _openReactionPicker(msg['id']),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      );
    }

    // ---------- MINI APP ----------
    Widget bubbleWidget;

    if (type == 'app') {
      final appName = (payload?['app'] ?? '').toString();
      Widget child;

      if (appName == "tetris") {
        final score = payload?['data']?['score'] ?? 0;
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset, size: 26, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tetris Score",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text("Score: $score",
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
        );
      } else if (appName == "hello") {
        final who = payload?['data']?['who'] ?? 'there';
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("👋", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text("Hello $who!",
                style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600)),
          ],
        );
      } else {
        child = Text("App message", style: TextStyle(color: textColor));
      }

      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
        child: child,
      );
    }

    // ---------- AI IMAGE ----------
    else if (type == "ai_image") {
      final url = msg['content'] ?? "";

      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _openReactionPicker(msg['id']),
            child: _ImageBubble(
              imageUrl: url,
              time: time,
              isMe: isMe,
            ),
          ),
          if (reaction != null) _reactionChip(isMe, reaction),
        ],
      );
    }

    // ---------- AI TEXT ----------
    else if (type == "ai") {
      final prompt = payload?['prompt'] ?? '';
      final response = payload?['response'] ?? '';

      bubbleWidget = GestureDetector(
        onLongPress: () => _openReactionPicker(msg['id']),
        child: _Bubble(
          isMe: isMe,
          bubbleColor: bubbleColor,
          time: time,
          textColor: textColor,
          senderName: isMe ? null : senderEmail.toString().split("@").first,
          onLongPress: () => _openReactionPicker(msg['id']),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (prompt.toString().isNotEmpty)
                Text("Q: $prompt",
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white70 : Colors.black54)),
              if (prompt.toString().isNotEmpty) const SizedBox(height: 4),
              Text(response.toString(),
                  style: TextStyle(fontSize: 15, color: textColor)),
            ],
          ),
        ),
      );
    }

    // ---------- EVENT REF ----------
    else if (type == 'event_ref') {
      // ignore: unused_local_variable
      final eventId = msg['eventId']?.toString();

      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
        child: Text("📅 Event"),
      );
    }

    // ---------- TEXT ----------
    else {
      final text = msg['content'] ?? payload?['text'] ?? '';
      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(msg["id"]),
        child: Text(text.toString(),
            style: TextStyle(fontSize: 17, color: textColor)),
      );
    }

    // ---------- FINAL RETURN (with reaction chip) ----------
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _openReactionPicker(msg['id']),
          child: bubbleWidget,
        ),
        if (reaction != null) _reactionChip(isMe, reaction),
      ],
    );
  }

  Widget _reactionChip(bool isMe, String emoji) {
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMe ? Colors.teal[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // ---------- Input row ----------

  Widget _buildInput(bool isDark) {
    // 🔥 FIX: Container ist jetzt außen, damit die Farbe bis ganz nach unten reicht
    if (userDeleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
        child: const Text(
          "Dieser Benutzer existiert nicht mehr.",
          style: TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }
    return Container(
      color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
      child: SafeArea(
        top:
            false, // Oben keine Safearea, damit es direkt an die Liste anschließt
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Text field (jetzt links)
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

              // Attach (jetzt rechts)
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                onPressed: _openAttachmentMenu,
              ),

              // Mini-apps toggle (jetzt rechts)
              // 🔥 ICON GEÄNDERT zu Puzzle (Extension)
              IconButton(
                icon: Icon(
                  _isSlashToolbarVisible
                      ? Icons.extension
                      : Icons.extension_outlined,
                  color: ChatTheme.myBubbleColor,
                ),
                onPressed: _toggleSlashToolbar,
              ),

              const SizedBox(width: 2),

              // Send button (ganz rechts)
              CircleAvatar(
                backgroundColor: ChatTheme.myBubbleColor,
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
      ),
    );
  }

  // ---------- Slash (mini-apps) toolbar ----------

  Widget _slashToolbar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _commandCard(
              icon: "👋",
              title: "Hello",
              description: "Sende eine freundliche Nachricht",
              onTap: () {
                _ctrl.text = "/hello ";
                _onTextChanged("/hello ");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "🖼️",
              title: "Bild senden",
              description: "Wähle ein Bild aus der Galerie",
              onTap: _pickFromGallery,
            ),
            _commandCard(
              icon: "🧠",
              title: "KI Image",
              description: "Bild mit KI generieren",
              onTap: () async {
                setState(() => _isSlashToolbarVisible = false);

                final imageUrl = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ImageBotScreen()),
                );

                if (imageUrl != null && imageUrl is String) {
                  await _sendAiImage(imageUrl);
                }
              },
            ),
            _commandCard(
              icon: "🎮",
              title: "Tetris",
              description: "Spiele ein Mini-Tetris",
              onTap: () {
                _ctrl.text = "/tetris";
                _onTextChanged("/tetris");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "📞",
              title: "Call Time",
              description: "Plane einen Gruppen- oder Privat-Call",
              onTap: () {
                _ctrl.text = "/calltime";
                _onTextChanged("/calltime");
                setState(() => _isSlashToolbarVisible = false);
              },
            ),
            _commandCard(
              icon: "🤖",
              title: "AI",
              description: "Chatte mit AI",
              onTap: _openAiPreview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
    final titleColor = isDarkMode ? Colors.white : Colors.black;
    final descColor = isDarkMode ? Colors.grey[400] : Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          color: cardColor,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: descColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Small helper widgets ----------

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
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 12 : 0),
      topRight: Radius.circular(isMe ? 0 : 12),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: borderRadius,
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

class _Bubble extends StatelessWidget {
  final Widget child;
  final String time;
  final bool isMe;
  final Color bubbleColor;
  final Color textColor;
  final String? senderName;
  final VoidCallback onLongPress;

  const _Bubble({
    required this.child,
    required this.time,
    required this.isMe,
    required this.bubbleColor,
    required this.textColor,
    this.senderName,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && senderName != null)
                Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              Container(
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
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    child,
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
            ],
          ),
        ),
      ),
    );
  }
}
