import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/call_service.dart';
import '../core/call/call_engine.dart';
import '../core/call/zego_call_engine.dart';
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

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  StreamSubscription<DocumentSnapshot>? _sub;

  late final AnimationController _dotController;
  late final Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();

    _dotController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _dotAnimation = IntTween(begin: 1, end: 3).animate(_dotController);

    _sub = _callService.listenCall(widget.callId).listen((snap) async {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;

      final status = data['status'];

      if (status == 'accepted') {
        await _sub?.cancel();

        final CallEngine engine = ZegoCallEngine();
        engine.init(
          callId: widget.callId,
          userId: widget.userId,
          userName: widget.userName,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callID: widget.callId,
              userID: widget.userId,
              userName: widget.userName,
              engine: engine,
            ),
          ),
        );
      }

      if (status == 'declined' || status == 'missed' || status == 'ended') {
        await _sub?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cancelCall() async {
    await _callService.endCall(widget.callId);
    await _callService.logCallMessage(
      conversationId: widget.callId.split("_").first,
      callId: widget.callId,
      type: "video",
      status: "cancelled",
    );
    if (mounted) Navigator.pop(context);
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _dotAnimation,
                    builder: (_, __) {
                      return Text(
                        "Calling${'.' * _dotAnimation.value}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: GestureDetector(
                  onTap: _cancelCall,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}