import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/core/call/call_engine.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ZegoCallEngine implements CallEngine {
  late String callId;
  late String userId;
  late String userName;

  @override
  void init({
    required String callId,
    required String userId,
    required String userName,
  }) {
    this.callId = callId;
    this.userId = userId;
    this.userName = userName;
  }

  @override
  Widget buildView() {
    return ZegoUIKitPrebuiltCall(
      appID: 1324862294,
      appSign: "197bf9ac83625712aa48ab5bd30e6df59dc96abb65f250895d9af4b573f2484b",
      userID: userId,
      userName: userName,
      callID: callId,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }

  @override
  Future<void> endCall() async {}

  @override
  void dispose() {}
}