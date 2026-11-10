import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexxchat_firebase/core/services/call_ringtone_service.dart';

import '../core/services/call_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String title;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.title,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallService _callService = CallService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  bool _closed = false;
  String _callType = 'video'; // default

  @override
  void initState() {
    super.initState();
   RingtoneService.startIncoming();
    _sub = _callService.listenCall(widget.callId).listen((snap) {
      final data = snap.data();
      if (data == null) return;

      // read call type once
      _callType = (data['callType'] ?? 'video').toString();

      final status = (data['status'] ?? '').toString();

      if (status == 'ended' ||
          status == 'declined' ||
          status == 'missed' ||
          status == 'cancelled') {
        RingtoneService.stop();
        _safeClose();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _safeClose() {
    if (_closed) return;
    _closed = true;

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAudio = _callType == 'audio';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white24,
                    child: isAudio
                        ? const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 48,
                          )
                        : Text(
                            widget.title.isNotEmpty
                                ? widget.title[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 42,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAudio
                        ? 'Incoming audio call'
                        : 'Incoming video call',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    GestureDetector(
                      onTap: () async {
                        RingtoneService.stop();
                        await widget.onDecline();
                        _safeClose();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),

                    // Accept
                    GestureDetector(
                      onTap: () async {
                        RingtoneService.stop();
                        await widget.onAccept();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isAudio ? Icons.call : Icons.videocam,
                          color: Colors.white,
                          size: 34,
                        ),
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