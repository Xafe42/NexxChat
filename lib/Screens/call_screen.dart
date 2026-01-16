import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/core/services/call_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _endCall() async {
    if (_ended) return;
    _ended = true;

    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = ((end - _startTime) / 1000).round();

    try {
      await _callService.finalizeCall(
        callId: widget.callID,
        status: "accepted",
        duration: duration,
      );
    } catch (_) {}

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _endCall();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _endCall();
      },
      child: ZegoUIKitPrebuiltCall(
        appID: 1324862294,
        appSign:
            "197bf9ac83625712aa48ab5bd30e6df59dc96abb65f250895d9af4b573f2484b",
        userID: widget.userID,
        userName: widget.userName,
        callID: widget.callID,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      ),
    );
  }
}