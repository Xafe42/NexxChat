import 'package:flutter/material.dart';
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

class _CallScreenState extends State<CallScreen> {
  late int _startTime;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _finishCallSafe() {
    if (_closed || !mounted) return;
    _closed = true;

    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = ((end - _startTime) / 1000).round();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
 @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Wir verhindern das direkte Schließen, um _finishCall() zu nutzen
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finishCallSafe(); // Wird aufgerufen, wenn Zego oder der User den Screen verlassen will
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