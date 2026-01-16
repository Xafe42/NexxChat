import 'dart:async';
import 'package:flutter/material.dart';
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
  StreamSubscription? _sub;
  bool _closed = false;

  @override
  void initState() {
    super.initState();

    // 🔴 نسمع للـ call document
    _sub = _callService.listenCall(widget.callId).listen((snap) {
      final data = snap.data();
      if (data == null) return;

      final status = data["status"];

      // ❌ caller سكّر / رفض / missed
      if (status == "ended" ||
          status == "declined" ||
          status == "missed") {
        _safeClose();
      }
    });
  }

  void _safeClose() {
    if (_closed) return;
    _closed = true;

    if (mounted) {
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

              // 👤 Avatar + Name
              Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white24,
                    child: Text(
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
                  const Text(
                    "Incoming video call",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // 🟢🔴 Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 🔴 Decline
                    GestureDetector(
                      onTap: () async {
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

                    // 🟢 Accept
                    GestureDetector(
                      onTap: () async {
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
                        child: const Icon(
                          Icons.call,
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