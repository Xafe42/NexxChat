import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/core/call/call_session.dart';
import 'package:provider/provider.dart';

import '../core/call/call_engine.dart';
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

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    //  Listen call status (for remote hangup / cancel / missed)
    _callSub = _callService.listenCall(widget.callId).listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      final status = data['status'];

      if ((status == 'ended' ||
           status == 'cancelled' ||
           status == 'missed') &&
          !_ended) {
        _ended = true;

        await widget.engine.endCall();

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  ///  User presses END CALL
  Future<void> _endCall() async {
    if (_ended) return;
    _ended = true;

    await widget.engine.endCall();

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  ///  App goes background → end call
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _endCall();
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
      canPop: true,
      onPopInvoked: (_) {
    context.read<CallSession>().minimize();
  },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video views (remote + local)
            Positioned.fill(
              child: widget.engine.buildView(),
            ),

            // End Call Button
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
}