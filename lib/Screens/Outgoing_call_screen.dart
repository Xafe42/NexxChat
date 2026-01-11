import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/call_service.dart';
import 'call_screen.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String title;
  final String userId;
  final String userName;

  const OutgoingCallScreen({
    super.key,
    required this.callId,
    required this.title,
    required this.userId,
    required this.userName,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final callService = CallService();
  late final StreamSubscription<DocumentSnapshot> _sub;

  @override
  void initState() {
    super.initState();

    _sub = callService.listenCall(widget.callId).listen((snap) {
      final data = snap.data();
      if (data == null) return;

      final status = data['status'];

      if (status == 'accepted') {
        _sub.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callID: widget.callId,
              userID: widget.userId,
              userName: widget.userName,
            ),
          ),
        );
      }

      if (status == 'declined' || status == 'missed' || status == 'ended') {
        _sub.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A84FF),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Calling…",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () async {
                await callService.endCall(widget.callId);
                Navigator.pop(context);
              },
              child: const Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    );
  }
}