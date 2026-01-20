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

  const CallScreen({
    super.key,
    required this.callId,
    required this.engine,
    required this.title,
    required this.userId,
    required this.userName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  final CallService _callService = CallService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ attach session + fullscreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<CallSession>();

      // مهم: ما تعاودش start إذا already active بنفس callId
      if (!session.isActive || session.callId != widget.callId) {
        session.start(
          callId: widget.callId,
          engine: widget.engine,
          title: widget.title,
          userId: widget.userId,
          userName: widget.userName,
        );
      }

      session.enterFullScreen();
    });

    // 👂 remote end/cancel/missed/declined
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
    if (_ended) return;
    if (!mounted) return;

    // ✅ يظهر mini overlay
    context.read<CallSession>().minimize();

    // ✅ يخرج من CallScreen ويرجع للشاشة اللي قبل
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Messenger behavior: background => minimize (مش end)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _minimizeAndPop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ✅ خلي الـ navigator ينجم يعمل pop عادي
      canPop: true,

      // ✅ وقت يصير pop (back system أو swipe) نعمل minimize
      onPopInvoked: (didPop) {
        if (!didPop) return;
        if (_ended) return;
        if (!mounted) return;
        context.read<CallSession>().minimize();
      },

      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: widget.engine.buildView()),

            // ⬇️ Minimize button
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
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
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

            // 🔴 End button
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
                      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}