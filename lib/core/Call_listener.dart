import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/call_screen.dart';
import 'package:nexxchat_firebase/core/call/webrtc_call_engine.dart';

import '../core/navigation.dart';
import '../core/services/call_service.dart';
import '../Screens/incoming_call_screen.dart';

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

  bool _incomingOpen = false;
  final Set<String> _blockedCalls = {};

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
        final data = doc.data();
        final callId = doc.id;

        if (_blockedCalls.contains(callId)) continue;
        if (data["callerId"] == user.uid) continue;

        final isGroup = data["isGroup"] == true;
        final receiverId = data["receiverId"];
        final members = List<String>.from(data["members"] ?? []);

        final isForMe =
            (!isGroup && receiverId == user.uid) ||
            (isGroup && members.contains(user.uid));

        if (!isForMe) continue;

        _incomingOpen = true;
        _openIncoming(callId, data);
        break;
      }
    });
  }

  void _openIncoming(String callId, Map<String, dynamic> data) {
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;

    final title = data["callerName"] ??
        (data["isGroup"] == true ? "Group Call" : "Incoming Call");

    navigator
        .push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          callId: callId,
          title: title,

          // ACCEPT
          onAccept: () async {
            final user = _auth.currentUser;
            if (user == null) return;

            _blockedCalls.add(callId);

            await _callService.acceptCall(callId, user.uid);

            final doc =
                await _db.collection("calls").doc(callId).get();

            final callType =
                (doc.data()?['callType'] ?? 'audio') as String;

            final engine = WebRTCCallEngine(
              isCaller: false,
              callType: callType,
            );

            await engine.init(
              callId: callId,
              userId: user.uid,
              userName: user.email ?? "User",
            );

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callId: callId,
                  engine: engine,
                  title: title,
                  userId: user.uid,
                  userName: user.email ?? "User",
                  callType: callType,
                ),
              ),
            );
          },

          // DECLINE
          onDecline: () async {
            _blockedCalls.add(callId);

            await _callService.declineCall(callId);

            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
      ),
    )
        .then((_) {
      _incomingOpen = false;
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