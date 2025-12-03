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

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  int startTime = 0;
  bool popped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _finishCall() {
    if (popped) return;
    popped = true;

    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = ((end - startTime) / 1000).round();

    Navigator.pop(context, {
      "type": "video",
      "status": "ended",
      "duration": duration,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Detect when user leaves the call screen (BACK or END CALL)
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _finishCall();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _finishCall();
        return true;
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