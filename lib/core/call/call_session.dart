import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/call_screen.dart';
import '../../core/call/call_engine.dart';

class CallSession extends ChangeNotifier {
  bool _active = false;
  bool _inFullScreen = false;

  String? callId;
  String? title;
  String? userId;
  String? userName;

  CallEngine? engine;

  /* ───────── GETTERS ───────── */

  bool get isActive => _active;
  bool get inFullScreen => _inFullScreen;

  /// show mini overlay ?
  bool get showMiniOverlay => _active && !_inFullScreen;

  /* ───────── START CALL ───────── */

  /// Attach an already-running call (engine already init)
  void start({
    required String callId,
    required CallEngine engine,
    required String title,
    required String userId,
    required String userName,
  }) {
    this.callId = callId;
    this.engine = engine;
    this.title = title;
    this.userId = userId;
    this.userName = userName;

    _active = true;
    _inFullScreen = true;

    notifyListeners();
  }

  /* ───────── UI STATE ───────── */

  /// Call screen opened (hide mini overlay)
  void enterFullScreen() {
    if (!_active) return;
    _inFullScreen = true;
    notifyListeners();
  }

  /// User pressed back → show mini overlay
  void minimize() {
    if (!_active) return;
    _inFullScreen = false;
    notifyListeners();
  }

  /* ───────── END CALL ───────── */

  /// End call from anywhere (mini / fullscreen / background)
  Future<void> end() async {
    if (!_active) return;

    try {
      await engine?.endCall();
    } catch (_) {}

    _active = false;
    _inFullScreen = false;

    callId = null;
    title = null;
    userId = null;
    userName = null;
    engine = null;

    notifyListeners();
  }

  /// 🔁 Used by mini overlay
  Widget buildCallScreen() {
    return CallScreen(
      callId: callId!,
      engine: engine!,
      title: title!,
      userId: userId!,
      userName: userName!,
    );
  }
}