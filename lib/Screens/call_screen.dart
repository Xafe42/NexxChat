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
  late int _startTime;
  bool _popped = false;

  final CallService _callService = CallService();

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

  Future<void> _finishCall() async {
    if (_popped) return;
    _popped = true;

    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = ((end - _startTime) / 1000).round();

    try {
      await _callService.logCallMessage(
        conversationId: widget.callID.split("_").first,
        callId: widget.callID,
        type: "video",
        status: "accepted",
        duration: duration,
      );
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _finishCall();
    }
  }
 @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Wir verhindern das direkte Schließen, um _finishCall() zu nutzen
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finishCall(); // Wird aufgerufen, wenn Zego oder der User den Screen verlassen will
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