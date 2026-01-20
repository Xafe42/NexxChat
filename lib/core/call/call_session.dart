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

  /// "video" | "audio"
  String callType = 'video';

  CallEngine? engine;

  /* ───────── GETTERS ───────── */

  bool get isActive => _active;
  bool get inFullScreen => _inFullScreen;

  bool get isAudio => callType == 'audio';
  bool get isVideo => callType == 'video';

  /// show mini overlay ?
  bool get showMiniOverlay => _active && !_inFullScreen;

  /* ───────── START / ATTACH CALL ───────── */

  /// Attach an already-running call (engine already initialized)
  void start({
    required String callId,
    required CallEngine engine,
    required String title,
    required String userId,
    required String userName,
    required String type, // "video" | "audio"
  }) {
    // 🔒 prevent duplicate start for same call
    if (_active && this.callId == callId) {
      _inFullScreen = true;
      notifyListeners();
      return;
    }

    this.callId = callId;
    this.engine = engine;
    this.title = title;
    this.userId = userId;
    this.userName = userName;
    callType = type;

    _active = true;
    _inFullScreen = true;

    notifyListeners();
  }

  /* ───────── UI STATE ───────── */

  /// Fullscreen opened (hide mini overlay)
  void enterFullScreen() {
    if (!_active || _inFullScreen) return;
    _inFullScreen = true;
    notifyListeners();
  }

  /// User pressed back → show mini overlay
  void minimize() {
    if (!_active || !_inFullScreen) return;
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
    callType = 'video';
    engine = null;

    notifyListeners();
  }

  /* ───────── NAVIGATION HELPER ───────── */

  /// Used by mini overlay / global navigator
  Widget buildCallScreen() {
    return CallScreen(
      callId: callId!,
      engine: engine!,
      title: title!,
      userId: userId!,
      userName: userName!,
      callType: callType,
    );
  }
}