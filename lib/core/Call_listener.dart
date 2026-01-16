import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Screens/incoming_call_screen.dart';
import '../Screens/call_screen.dart';
import '../core/services/call_service.dart';
import '../core/navigation.dart';

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

  bool _incomingOpen = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final user = _auth.currentUser;
    if (user == null) return;

    _sub = _db
        .collection("calls")
        .where("status", isEqualTo: "ringing")
        .snapshots()
        .listen((snapshot) {
      if (_incomingOpen) return;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final callId = doc.id;

        if (data["callerId"] == user.uid) continue;

        final isGroup = data["isGroup"] == true;
        final receiverId = data["receiverId"];
        final members = List<String>.from(data["members"] ?? []);

        final isForMe =
            (!isGroup && receiverId == user.uid) ||
            (isGroup && members.contains(user.uid));

        if (!isForMe) continue;

        _incomingOpen = true;
        _sub?.cancel(); 
        _openIncoming(callId, data);
        break;
      }
    });
  }

  void _openIncoming(String callId, Map<String, dynamic> data) {
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;

    final title =
        data["callerName"] ??
        (data["isGroup"] == true ? "Group Call" : "Incoming Call");

    navigator
        .push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          callId: callId,
          title: title,
          onAccept: () async {
            await CallService().acceptCall(callId);

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callID: callId,
                  userID: _auth.currentUser!.uid,
                  userName: _auth.currentUser!.email ?? "User",
                ),
              ),
            );
          },
          onDecline: () async {
            await CallService().declineCall(callId);
            navigator.pop();
          },
        ),
      ),
    )
        .then((_) {
      _incomingOpen = false;
      _startListening(); 
    });
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