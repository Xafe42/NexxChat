import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nexxchat_firebase/core/services/call_service.dart';
import '../core/call/webrtc_call_engine.dart';
import 'call_screen.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String title;
  final String userId;
  final String userName;
  final String callType; // ✅ audio | video

  const OutgoingCallScreen({
    super.key,
    required this.callId,
    required this.title,
    required this.userId,
    required this.userName,
    required this.callType,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  late final AnimationController _dotController;
  late final Animation<int> _dotAnimation;

  bool _navigated = false;
  bool _closed = false;

  bool get _isAudio => widget.callType == 'audio';

  @override
  void initState() {
    super.initState();

    _dotController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _dotAnimation = IntTween(begin: 1, end: 3).animate(_dotController);

    _sub = _callService.listenCall(widget.callId).listen(_onCallUpdate);
  }

  Future<void> _onCallUpdate(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    final data = snap.data();
    if (data == null) return;

    final status = (data['status'] ?? '').toString();

   if ((status == 'accepted' || status == 'active') && !_navigated){
      _navigated = true;

      final engine = WebRTCCallEngine(
        isCaller: true,
        callType: widget.callType, 
      );

      await engine.init(
        callId: widget.callId,
        userId: widget.userId,
        userName: widget.userName,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callId: widget.callId,
            engine: engine,
            title: widget.title,
            userId: widget.userId,
            userName: widget.userName,
            callType: widget.callType, // ✅ مهم
          ),
        ),
      );
      return;
    }

    if (status == 'declined' ||
        status == 'missed' ||
        status == 'ended' ||
        status == 'cancelled') {
      _safeClose();
    }
  }

  Future<void> _cancelCall() async {
    if (_closed) return;
    _closed = true;

    await _callService.cancelCall(widget.callId);

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _safeClose() {
    if (_closed) return;
    _closed = true;

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dotController.dispose();
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

              Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white24,
                    child: _isAudio
                        ? const Icon(Icons.call,
                            color: Colors.white, size: 48)
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAudio
                        ? 'Outgoing audio call'
                        : 'Outgoing video call',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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