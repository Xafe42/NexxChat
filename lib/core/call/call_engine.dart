import 'package:flutter/material.dart';

abstract class CallEngine {
  Future<void> init({
    required String callId,
    required String userId,
    required String userName,
  });

  Widget buildView();

  Future<void> endCall();

  ///  Mute / Unmute microphone
  void setMuted(bool muted);

  ///  Speaker routing (Android will still auto-route to BT/headset when connected)
  Future<void> setSpeaker(bool enabled);

  /// Enable/disable local camera (video track)
  void setVideoEnabled(bool enabled);

  /// Switch front/back camera (video only)
  Future<void> switchCamera();

  void dispose();
}