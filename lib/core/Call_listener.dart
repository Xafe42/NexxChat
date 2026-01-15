import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Screens/incoming_call_screen.dart';
import '../core/services/call_service.dart';

class GlobalCallListener extends StatefulWidget {
  final Widget child;

  const GlobalCallListener({super.key, required this.child});

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  StreamSubscription<QuerySnapshot>? _sub;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _callService = CallService();

  String? _activeCallId;

  @override
  void initState() {
    super.initState();
    _listenIncomingCalls();
  }

  void _listenIncomingCalls() {
    final user = _auth.currentUser;
    if (user == null) return;

    _sub = _db
        .collection("calls")
        .where("status", isEqualTo: "ringing")
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final isGroup = data["isGroup"] == true;
        final receiverId = data["receiverId"];
        final members = List<String>.from(data["members"] ?? []);

        final isForMe =
            (!isGroup && receiverId == user.uid) ||
            (isGroup && members.contains(user.uid));

        if (!isForMe) continue;

        if (_activeCallId == doc.id) continue;
        _activeCallId = doc.id;

        _showIncomingCall(doc.id, data);
      }
    });
  }

  Future<void> _showIncomingCall(String callId, Map<String, dynamic> data) async {
    if (!mounted) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          callId: callId,
          title: data["isGroup"] == true ? "Group Call" : "Incoming Call",
          onAccept: () async {
            await _callService.acceptCall(callId);
            Navigator.pop(context);
          },
          onDecline: () async {
            await _callService.endCall(callId);
            Navigator.pop(context);
          },
        ),
      ),
    );

    _activeCallId = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}