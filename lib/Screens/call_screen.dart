import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/call/call_engine.dart';
import '../core/call/call_session.dart';
import '../core/services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final CallEngine engine;
  final String title;
  final String userId;
  final String userName;
  final String callType; // "video" | "audio"

  const CallScreen({
    super.key,
    required this.callId,
    required this.engine,
    required this.title,
    required this.userId,
    required this.userName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

  bool _ended = false;

  bool get _isAudio => widget.callType == 'audio';

  /* ───────── INIT ───────── */

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<CallSession>();

      if (!session.isActive || session.callId != widget.callId) {
        session.start(
          callId: widget.callId,
          engine: widget.engine,
          title: widget.title,
          userId: widget.userId,
          userName: widget.userName,
          type: widget.callType,
        );
      }

      session.enterFullScreen();
    });

    _callSub = _callService.listenCall(widget.callId).listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString();

      if (!_ended &&
          (status == 'ended' ||
              status == 'cancelled' ||
              status == 'missed' ||
              status == 'declined')) {
        _ended = true;

        if (!mounted) return;
        await context.read<CallSession>().end();

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  /* ───────── ACTIONS ───────── */

  Future<void> _endCall() async {
    if (_ended) return;
    _ended = true;

    if (!mounted) return;
    await context.read<CallSession>().end();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _minimizeAndPop() {
    if (_ended || !mounted) return;

    context.read<CallSession>().minimize();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _minimizeAndPop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSub?.cancel();
    super.dispose();
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop || _ended || !mounted) return;
        context.read<CallSession>().minimize();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 🎥 VIDEO / 🎧 AUDIO VIEW
            Positioned.fill(
              child: _isAudio
                  ? _buildAudioView()
                  : widget.engine.buildView(),
            ),

            // ⬇️ TOP BAR
            Positioned(
              top: 48,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _minimizeAndPop,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isAudio ? 'Audio Call' : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔴 END CALL
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _endCall,
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
            ),
          ],
        ),
      ),
    );
  }

  /* ───────── AUDIO UI ───────── */

  Widget _buildAudioView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white24,
            child: Text(
              widget.title.isNotEmpty
                  ? widget.title[0].toUpperCase()
                  : '?',
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
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Audio call in progress',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}