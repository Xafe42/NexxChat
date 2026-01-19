import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/core/call/call_engine.dart';
import 'package:nexxchat_firebase/core/services/Call_service.dart';

class CallScreen extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final CallEngine engine;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    required this.engine,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService();
  late int _startTime;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now().millisecondsSinceEpoch;

    widget.engine.init(
      callId: widget.callID,
      userId: widget.userID,
      userName: widget.userName,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.engine.dispose();
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_ended) return;
    _ended = true;

    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = ((end - _startTime) / 1000).round();

    try {
      await widget.engine.endCall();
      await _callService.finalizeCall(
        callId: widget.callID,
        status: "accepted",
        duration: duration,
      );
    } catch (_) {}

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _endCall(),
      child: widget.engine.buildView(),
    );
  }
}