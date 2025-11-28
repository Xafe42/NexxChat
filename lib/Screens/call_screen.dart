import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Hier wird deine AppID und AppSign von der ZegoCloud Console eingetragen
    // Melde dich bei ZegoCloud an, erstelle ein Projekt und kopiere die Daten hier rein.
    // https://console.zegocloud.com/dashboard
    const int yourAppID = 1324862294; // 🔴 DEINE APP ID
    const String yourAppSign = "197bf9ac83625712aa48ab5bd30e6df59dc96abb65f250895d9af4b573f2484b"; // 🔴 DEIN APP SIGN

    return ZegoUIKitPrebuiltCall(
      appID: yourAppID,
      appSign: yourAppSign,
      userID: userID,
      userName: userName,
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}