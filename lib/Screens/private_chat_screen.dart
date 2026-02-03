import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nexxchat_firebase/Screens/image_bot_screen.dart';
import 'package:nexxchat_firebase/Screens/outgoing_call_screen.dart';
import 'package:nexxchat_firebase/core/services/call_service.dart';
import 'package:nexxchat_firebase/theme/chat_theme.dart';
import 'package:nexxchat_firebase/widgets/call_time_message_card.dart';
import 'package:nexxchat_firebase/widgets/calltime_preview.dart';
import 'package:path/path.dart' as path;

import '../Screens/TetrisFullScreenPage.dart';
import '../apps/event_app.dart';
import '../apps/hello_app.dart';
import '../core/commands/command_router.dart';
import '../core/models/chat_command.dart';
import '../core/services/chat_service.dart';
import '../widgets/ai_preview.dart'; // Enthält die fetchAi Logik
import '../widgets/event_preview.dart';
import '../widgets/full_screen_image_page.dart';
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
  String? otherUserPhotoUrl;
  final Set<String> _handledScheduledCalls = {};
  User? _user;

  bool _sending = false;
  bool _lastTypingState = false;
  bool _showScrollBtn = false;

  // ignore: unused_field
  String _raw = "";
  ChatCommand? _aktiveCmd;
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
        final userDoc = await _db.collection("users").doc(otherUserId!).get();
        if (!userDoc.exists) {
          if (mounted) setState(() => userDeleted = true);
        } else {
          if (mounted) {
            setState(() {
              otherUserPhotoUrl = userDoc.data()?['photoURL'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Fehler beim Laden des Users: $e");
    }
  }

  Future<void> _sendV1Notification(
      String partnerToken, String messageText) async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "nexxchat-1f0fc",
      "private_key_id": "c533a8e4f04d4ab3d1501c5bbdf694a360254c51",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDLpMMgZDDBx0lP\nswJUm4FBIkPlHWI+UAz/sLRBV5gcf5ezrU/IqQ4Fw7Bt+56X0Y2uVKtpTh69M+dZ\n7zWf8MS4hzKm3XlpAWn79xGi+0H03LBaN4Zq4h145PRclavWusMpepa9dJsClXUC\nef/wQlDonGbYHe0jBEMDFB1ohU0sA7nTowUhDR3Tgixkj+LklGjBKnvJnpaQxptE\n7KLHYUmxAe5Z+8giWKVFa+/+99LRxH/ISdWRtIiuefrm2qVRoFWkccRQSB6HW0Wr\n5rRU/RWhzXYvSkrLB5lCwFidd7e4xXf92uFyS+0WLBwi2JIgchoCaAsMm+7AixoF\ntsevNHutAgMBAAECggEACiFu7JJXY5hyovKci9F1l2QpPQFedQud7e1gNjzxjf9h\n8FgPl0OjtTE0OnBxRguwcOr44QL4IADwQibWg9eiLazaHfd4FftyRozWtYUq1Y/R\n/Rb0iqYnga9gIaf3dbXyRgK5c4DUwkblnIMtsonWBRBcxGUOujZ4z/Mk+GFjQqxw\n+hHXb5UGG2puG6MoM044EHQrfc1U+tEkiD+u2QCWzbVkjVF+gMnuRqBsRpoXvPK+\ngicQ3Xt6wimf1XvwxaHLbQSl4mY0mtbzhINdkq39D+71l0y1nnPpicbgwDPVJ/H2\ndBJklvFGnPtXwOUQwgSquGjSYIFv3t9I2OLlZRHqQQKBgQD4qeZ6drLs0S6AWu7Q\noWgyXursOk5spivZpwX5GiMETyg+fufuYu04JIzWlPRVEjXDKbppc9rriRoVBGmn\nFLaMopFXflJYDXvINzzFsL+Ur/pGJ2So1s/qExSCHSA0pC8ePUIDog8DOLHUfIpk\ny/oB0MJy4kyHEW8UR0rZ4jHWwQKBgQDRptXsXzXXOXIyB4cN3j1SG6OU+uHHjnMn\nbbYM5NJlycwpJ7D8fa7A4wUmkIToR3rVwR+gNj5CdkfZ3LodqRdSurDoVLYI+vVF\neP3dcRkmGe2bs+8PxfdCEMyZTpyLKnxKFaXockcd8alBrtbU94tzcxxlCqk0RHIB\nh44fY85r7QKBgQCkvhNHUTqrcM7pFNWhfT4GGSJ1DRAGJXVpxqFLbsiCQ1s7RGKu\nafYVuwlf5OGXNvBNc2jgEnSYlYWlJP5GRo/GzrGSEMvHMG+wrv/hTX8vqAMc1V54\ CZFH2Ao/RcKffaMF2rnQpF5j2Pzf9P7PVuA0sbUR3eGrnp5EBhOOFLDGQQKBgHHI\nCfHu+lmEY+WjEDkGlGErfuwr/L1BIl4TvOnihg2YJ6VuVS+zRlSI4RK8/GTT5mZ8\nGZ3p0oBfkT87/AZ87puHltuAngrhqJu7vougBfYXvEz0qpn05uyEEYZik7Mzq6DJ\nfvFYlCA8N4/eQ9nxP024+4Aa+RnUy8rotslycWVBAoGAL2fXL9HLEqivaSpYy06z\nqu9QT96oGYzPzDaBa0fDxtcueKBIH2r/mLcWJmHAyB85F0Fmw5KOf6dcNA4SQCGI\nCUDMfvuPALeIGzsG8V4EjUnSVVXHXgNVjuveFnYFgjAgew/It/NgONgfdFcujt0T\nIACeOc0leZMWG6cNYjD47rA=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@nexxchat-1f0fc.iam.gserviceaccount.com",
      "client_id": "102132668974376071943",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40nexxchat-1f0fc.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    try {
      final credentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await auth.clientViaServiceAccount(credentials, scopes);

      final String url =
          'https://fcm.googleapis.com/v1/projects/nexxchat-1f0fc/messages:send';

      await client.post(
        Uri.parse(url),
        body: jsonEncode({
          'message': {
            'token': partnerToken,
            'notification': {
              'title': _user?.email?.split('@')[0] ?? "NexxChat",
              'body': messageText,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'chat_messages',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          }
        }),
      );
      client.close();
    } catch (e) {
      debugPrint("Fehler beim Senden der Benachrichtigung: $e");
    }
  }

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
    } catch (_) {}
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

        if (_handledScheduledCalls.contains(msgId)) continue;

        final diff = nowMs - scheduledAt;
        final isDue = diff >= 0 && diff < 2 * 60 * 1000;

        if (status == "scheduled" && isDue) {
          _handledScheduledCalls.add(msgId);
        }
      }
    });
  }

  void _onTextChanged(String value) {
    _raw = value;
    _setTyping(value.trim().isNotEmpty);

    setState(() {
      _aktiveCmd = CommandRouter.detect(value);

      if (value.startsWith("/") && _aktiveCmd == null) {
        _isSlashToolbarVisible = true;
      } else {
        _isSlashToolbarVisible = false;
      }

      if (_aktiveCmd?.type == "tetris") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openTetris();
        });
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _user == null) return;

    // --- NEUE KI LOGIK ---
    if (text.startsWith("/ai ")) {
      final prompt = text.replaceFirst("/ai ", "").trim();
      if (prompt.isEmpty) return;

      setState(() => _sending = true);
      _ctrl.clear();

      try {
        // 1. Prompt als normale Textnachricht senden
        await _chatService.sendTextMessage(
          conversationId: widget.conversationId,
          text: "🤖 Fragt KI: $prompt",
          senderUid: _user!.uid,
          senderEmail: _user!.email ?? '',
        );

        // 2. KI Antwort holen
        final response = await fetchAi(prompt);

        // 3. Antwort als speziellen Typ 'ai' speichern
        await _sendAiMessage(prompt: prompt, response: response);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    if (_aktiveCmd != null) {
      final cmd = _aktiveCmd!;

      if (cmd.type == "hello") {
        await _sendHelloCommand(cmd);
        _resetInput();
        return;
      }
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .update({
      "hiddenChats": FieldValue.arrayRemove([widget.conversationId])
    });

    setState(() => _sending = true);
    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        text: text,
        senderUid: _user!.uid,
        senderEmail: _user!.email ?? '',
      );

      if (otherUserId != null) {
        final userDoc = await _db.collection('users').doc(otherUserId!).get();
        final String? partnerToken = userDoc.data()?['fcmToken'];

        if (partnerToken != null) {
          await _sendV1Notification(partnerToken, text);
        }
      }

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
      'senderId': 'nexx_bot', // Spezial ID für den Bot
      'receiverId': receiverUid,
      'sender': 'NexxAI@bot.com',
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
            if (emoji == "REMOVE_ALL") {
              _removeAllMyReactions(messageId);
            } else {
              _toggleReaction(messageId, emoji);
            }
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

  Future<void> _toggleReaction(String messageId, String emoji) async {
    if (_user == null) return;
    final myUid = _user!.uid;

    final msgRef = _db
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(messageId);

    final snap = await msgRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final Map<String, dynamic> reactions = data['reactions'] ?? {};

    final List<dynamic> usersWhoReacted = reactions[emoji] ?? [];
    final bool alreadyReacted = usersWhoReacted.contains(myUid);

    if (alreadyReacted) {
      await msgRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([myUid])
      });
    } else {
      await msgRef.update({
        'reactions.$emoji': FieldValue.arrayUnion([myUid])
      });
    }
  }

  Future<void> _removeAllMyReactions(String messageId) async {
    if (_user == null) return;
    final myUid = _user!.uid;

    final msgRef = _db
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(messageId);

    final snap = await msgRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final Map<String, dynamic> reactions = data['reactions'] ?? {};

    Map<String, dynamic> updates = {};
    reactions.forEach((emoji, userList) {
      if (userList is List && (userList).contains(myUid)) {
        updates['reactions.$emoji'] = FieldValue.arrayRemove([myUid]);
      }
    });

    if (updates.isNotEmpty) {
      await msgRef.update(updates);
    }
  }

  Future<void> _sendImage(File file) async {
    if (_user == null) return;

    setState(() => _sending = true);

    try {
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
    } catch (e) {
      debugPrint("Fehler beim Bildversand: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
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

  void _toggleSlashToolbar() {
    setState(() {
      _isSlashToolbarVisible = !_isSlashToolbarVisible;
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
    final bubbleMe = ChatTheme.myBubbleColor;
    final bubbleOther = isDark ? const Color(0xFF262D31) : Colors.white;

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
                    radius: 20,
                    backgroundColor:
                        isGroup ? ChatTheme.myBubbleColor : Colors.white24,
                    child: ClipOval(
                      child: isGroup
                          ? _buildGroupAvatar(convData)
                          : _buildPrivateAvatar(displayTitle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
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
                            const Text(
                              "Tippen für Infos",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (!isGroup && convData != null && !userDeleted)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.white),
                    onPressed: () async {
                      if (_user == null) return;

                      final members =
                          List<String>.from(convData!['members'] ?? []);
                      final otherUserId = members.firstWhere(
                        (m) => m != _user!.uid,
                        orElse: () => "",
                      );
                      if (otherUserId.isEmpty) return;

                      final callId = await CallService().startPrivateCall(
                        conversationId: widget.conversationId,
                        callerId: _user!.uid,
                        receiverId: otherUserId,
                        type: 'audio',
                      );

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutgoingCallScreen(
                            callId: callId,
                            title: widget.title,
                            userId: _user!.uid,
                            userName: _user!.email ?? "User",
                            callType: 'audio',
                          ),
                        ),
                      );
                    },
                  ),

                if (!isGroup && convData != null && !userDeleted)
                  IconButton(
                    icon:
                        const Icon(Icons.videocam_rounded, color: Colors.white),
                    onPressed: () async {
                      if (_user == null) return;

                      final members =
                          List<String>.from(convData!['members'] ?? []);
                      final otherUserId = members.firstWhere(
                        (m) => m != _user!.uid,
                        orElse: () => "",
                      );
                      if (otherUserId.isEmpty) return;

                      final callId = await CallService().startPrivateCall(
                        conversationId: widget.conversationId,
                        callerId: _user!.uid,
                        receiverId: otherUserId,
                        type: 'video',
                      );

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutgoingCallScreen(
                            callId: callId,
                            title: widget.title,
                            userId: _user!.uid,
                            userName: _user!.email ?? "User",
                            callType: 'video',
                          ),
                        ),
                      );
                    },
                  ),

                if (isGroup && convData != null)
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.white),
                    onPressed: () async {
                      if (_user == null) return;

                      final members =
                          List<String>.from(convData!['members'] ?? []);
                      if (members.isEmpty) return;

                      final callId = await CallService().startGroupCall(
                        conversationId: widget.conversationId,
                        callerId: _user!.uid,
                        members: members,
                        type: 'audio',
                      );

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutgoingCallScreen(
                            callId: callId,
                            title: widget.title,
                            userId: _user!.uid,
                            userName: _user!.email ?? "User",
                            callType: 'audio', 
                          ),
                        ),
                      );
                    },
                  ),

                if (isGroup && convData != null)
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.white),
                    onPressed: () async {
                      if (_user == null) return;

                      final members =
                          List<String>.from(convData!['members'] ?? []);
                      if (members.isEmpty) return;

                      final callId = await CallService().startGroupCall(
                        conversationId: widget.conversationId,
                        callerId: _user!.uid,
                        members: members,
                      );

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutgoingCallScreen(
                            callId: callId,
                            title: widget.title,
                            userId: _user!.uid,
                            userName: _user!.email ?? "User",
                            callType: 'video',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
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
                            return const Center(
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
                              if (index == docs.length + 1) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
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
                                      '🔒 Messages are end-to-end encrypted.',
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
                                final ts = (msgData['timestamp'] ??
                                    msgData['time']) as Timestamp?;
                                final dt = ts?.toDate() ?? DateTime.now();
                                return _DateChip(label: _formatDateLabel(dt));
                              }

                              final msg = docs[index].data();
                              final msgId = docs[index].id;
                              final senderEmail = msg['sender'] ?? '';
                              final isMe = msg['senderId'] == _user?.uid ||
                                  senderEmail == _user?.email;

                              final type = msg['type'] ?? 'text';
                              final ts = (msg['timestamp'] ?? msg['time'])
                                  as Timestamp?;
                              final dt = ts?.toDate() ?? DateTime.now();
                              final time = _formatTime(ts);

                              bool showDateChip = false;
                              if (index < docs.length - 1) {
                                final nextMsg = docs[index + 1].data();
                                final nextTs = (nextMsg['timestamp'] ??
                                    nextMsg['time']) as Timestamp?;
                                final nextDt =
                                    nextTs?.toDate() ?? DateTime.now();

                                if (dt.year != nextDt.year ||
                                    dt.month != nextDt.month ||
                                    dt.day != nextDt.day) {
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
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection("conversations")
                          .doc(widget.conversationId)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.data() == null) {
                          return const SizedBox.shrink();
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

                        if (!isTyping) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 18, bottom: 4, top: 2),
                          child: Row(
                            children: [
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
                if (_aktiveCmd?.type == "calltime")
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: CallTimePreview(
                      onCancel: _resetInput,
                      onSend: (data) => _sendScheduledCall(data),
                    ),
                  ),
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
                if (_isSlashToolbarVisible) _slashToolbar(),
              ],
            ),
          );
        });
  }

  void _openImageActions({
    required String messageId,
    required bool isMe,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🔥'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _toggleReaction(messageId, emoji);
                    },
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(),

              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete image',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteImageMessage(messageId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteImageMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'type': 'deleted',
      'content': '🗑 Image deleted',
      'payload': {},
    });
  }

  Widget _buildPrivateAvatar(String name) {
    if (otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty) {
      return Image.network(
        otherUserPhotoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _privateFallback(name),
      );
    }

    return _privateFallback(name);
  }

  Widget _privateFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(Map<String, dynamic>? convData) {
    final url = convData?['groupPhotoURL'];

    if (url != null && url.toString().isNotEmpty) {
      return Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(Icons.groups, color: Colors.white, size: 20);
        },
      );
    }

    return const Icon(Icons.groups, color: Colors.white, size: 20);
  }

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

    Widget bubbleWidget;

    // --- NEUES KI DESIGN ---
    if (type == 'ai') {
      final response = payload?['response'] ?? '';
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                : [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_rounded, 
                      size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    Text("NexxAI", 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w900,
                        color: Colors.blueAccent.shade400,
                        letterSpacing: 1.1,
                      )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Text(response.toString(),
                    style: TextStyle(
                      fontSize: 15, 
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(time,
                    style: TextStyle(
                      fontSize: 10, 
                      color: isDark ? Colors.white54 : Colors.grey)),
                ),
              )
            ],
          ),
        ),
      );
    }

    if (type == 'calltime') {
      final status = msg['status'] ?? 'scheduled';
      if (status != 'scheduled') return const SizedBox.shrink();

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: CallTimeMessageCard(
            payload: msg["payload"] ?? {},
            conversationId: widget.conversationId,
            messageId: messageId,
          ),
        ),
      );
    }

    if (type == 'image' || type == 'ai_image') {
      final url = (msg['content'] ?? payload?['url'] ?? '').toString();

      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () =>
                _openImageActions(messageId: messageId, isMe: isMe),
            child: _ImageBubble(
              imageUrl: url,
              time: time,
              isMe: isMe,
            ),
          ),
          _buildReactionsDisplay(msg, messageId),
        ],
      );
    }
    if (type == 'deleted') {
      return _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor.withValues(alpha: 0.5),
        textColor: Colors.grey,
        time: time,
        onLongPress: () {},
        child: const Text(
          '🗑 Image deleted',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    if (type == 'call') {
      final status = msg['status'];
      final duration = msg['duration'] ?? 0;
      final callType = msg['callType'] ?? 'video';
      final isAudio = callType == 'audio';

      late String text;

      if (status == "missed") {
        text =
            isAudio ? "📞 Verpasster Audioanruf" : "🎥 Verpasster Videoanruf";
      } else {
        final mm = (duration ~/ 60).toString().padLeft(2, '0');
        final ss = (duration % 60).toString().padLeft(2, '0');

        text = isAudio
            ? "📞 Audioanruf beendet – Dauer: $mm:$ss"
            : "🎥 Videoanruf beendet – Dauer: $mm:$ss";
      }

      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        textColor: textColor,
        time: time,
        onLongPress: () => _openReactionPicker(messageId),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      );
    } else if (type == 'app') {
      final appName = (payload?['app'] ?? '').toString();
      Widget child;

      if (appName == "tetris") {
        final score = payload?['data']?['score'] ?? 0;
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset, size: 26, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
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
            Flexible(
              child: Text("Hello $who!",
                  style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w600)),
            ),
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
        onLongPress: () => _openReactionPicker(messageId),
        child: child,
      );
    } else if (type == 'event_ref') {
      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(messageId),
        child: const Text("📅 Event"),
      );
    } else {
      final text = msg['content'] ?? payload?['text'] ?? '';
      bubbleWidget = _Bubble(
        isMe: isMe,
        bubbleColor: bubbleColor,
        time: time,
        textColor: textColor,
        senderName: isMe ? null : senderEmail.toString().split("@").first,
        onLongPress: () => _openReactionPicker(messageId),
        child: Text(text.toString(),
            style: TextStyle(fontSize: 17, color: textColor)),
      );
    }

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _openReactionPicker(messageId),
          child: bubbleWidget,
        ),
        _buildReactionsDisplay(msg, messageId),
      ],
    );
  }

  Widget _buildReactionsDisplay(Map<String, dynamic> msg, String messageId) {
    final Map<String, dynamic> reactions = msg['reactions'] ?? {};
    if (reactions.isEmpty) return const SizedBox.shrink();

    final activeReactions = reactions.entries
        .where((e) => e.value is List && (e.value as List).isNotEmpty)
        .toList();

    if (activeReactions.isEmpty) return const SizedBox.shrink();

    final isMe = msg['senderId'] == _user?.uid;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: activeReactions.map((entry) {
          final emoji = entry.key;
          final List users = entry.value as List;
          final count = users.length;
          final bool iReacted = users.contains(_user?.uid);

          return GestureDetector(
            onTap: () => _toggleReaction(messageId, emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iReacted
                    ? ChatTheme.myBubbleColor.withValues(alpha: 0.2)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
                border: iReacted
                    ? Border.all(color: ChatTheme.myBubbleColor, width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: iReacted
                            ? ChatTheme.myBubbleColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInput(bool isDark) {
    if (userDeleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
        child: const Text("Dieser Benutzer existiert nicht mehr.",
            style: TextStyle(color: Colors.red, fontSize: 14)),
      );
    }
    return Container(
      color: isDark ? Colors.grey[900] : const Color(0xFFEEEEEE),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
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
                        hintText: "Nachricht senden", border: InputBorder.none),
                  ),
                ),
              ),
              IconButton(
                  icon: Icon(Icons.attach_file,
                      color: isDark ? Colors.white70 : Colors.grey[700]),
                  onPressed: _openAttachmentMenu),
              IconButton(
                icon: Icon(
                    _isSlashToolbarVisible
                        ? Icons.extension
                        : Icons.extension_outlined,
                    color: ChatTheme.myBubbleColor),
                onPressed: _toggleSlashToolbar,
              ),
              const SizedBox(width: 2),
              CircleAvatar(
                backgroundColor: ChatTheme.myBubbleColor,
                child: IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
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
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _commandCard(
                  icon: "👋",
                  title: "Hello",
                  description: "Sende Nachricht",
                  onTap: () {
                    _ctrl.text = "/hello ";
                    _onTextChanged("/hello ");
                    setState(() => _isSlashToolbarVisible = false);
                  }),
              _commandCard(
                  icon: "🖼️",
                  title: "Bild senden",
                  description: "Galerie",
                  onTap: _pickFromGallery),
              _commandCard(
                  icon: "🧠",
                  title: "KI Image",
                  description: "KI generieren",
                  onTap: () async {
                    setState(() => _isSlashToolbarVisible = false);
                    final imageUrl = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ImageBotScreen()));
                    if (imageUrl != null && imageUrl is String) {
                      await _sendAiImage(imageUrl);
                    }
                  }),
              _commandCard(
                  icon: "🎮",
                  title: "Tetris",
                  description: "Mini-Tetris",
                  onTap: () {
                    _ctrl.text = "/tetris";
                    _onTextChanged("/tetris");
                    setState(() => _isSlashToolbarVisible = false);
                  }),
              _commandCard(
                  icon: "📞",
                  title: "Call Time",
                  description: "Plane einen Gruppen- oder Privat-Call",
                  onTap: () {
                    _ctrl.text = "/calltime";
                    _onTextChanged("/calltime");
                    setState(() => _isSlashToolbarVisible = false);
                  }),
              _commandCard(
                  icon: "🤖",
                  title: "AI",
                  description: "Frag die KI direkt hier im Chat",
                  onTap: () {
                    _ctrl.text = "/ai ";
                    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
                    setState(() => _isSlashToolbarVisible = false);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _commandCard(
      {required String icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
            color: isDarkMode ? Colors.grey[800] : Colors.white),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black)),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey.shade700)),
              ]),
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
              borderRadius: BorderRadius.circular(16)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87)),
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final String time;
  final bool isMe;

  const _ImageBubble(
      {required this.imageUrl, required this.time, required this.isMe});

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
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(imageUrl: imageUrl))),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 12 : 0),
                    topRight: Radius.circular(isMe ? 0 : 12),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  width: 230,
                  height: 260,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 230,
                          height: 260,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator())),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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

  const _Bubble(
      {required this.child,
      required this.time,
      required this.isMe,
      required this.bubbleColor,
      required this.textColor,
      this.senderName,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && senderName != null)
                Text(senderName!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 12 : 0),
                        topRight: Radius.circular(isMe ? 0 : 12),
                        bottomLeft: const Radius.circular(12),
                        bottomRight: const Radius.circular(12))),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      child,
                      const SizedBox(height: 3),
                      Text(time,
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 11)),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}