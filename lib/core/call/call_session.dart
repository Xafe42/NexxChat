import 'package:flutter/material.dart';
import 'call_engine.dart';

enum CallViewMode {
  none,        // no call
  fullscreen, // CallScreen
  minimized,  // mini overlay (later)
}

class CallSession extends ChangeNotifier {
  String? callId;
  String? title;
  String? userId;
  String? userName;

  CallEngine? engine;

  CallViewMode viewMode = CallViewMode.none;

  bool get hasActiveCall => engine != null && callId != null;

  /* ───────── START CALL ───────── */

  void startCall({
    required String callId,
    required String title,
    required String userId,
    required String userName,
    required CallEngine engine,
  }) {
    this.callId = callId;
    this.title = title;
    this.userId = userId;
    this.userName = userName;
    this.engine = engine;

    viewMode = CallViewMode.fullscreen;
    notifyListeners();
  }

  /* ───────── MINIMIZE ───────── */

  void minimize() {
    if (!hasActiveCall) return;
    viewMode = CallViewMode.minimized;
    notifyListeners();
  }

  /* ───────── RESTORE ───────── */

  void restore() {
    if (!hasActiveCall) return;
    viewMode = CallViewMode.fullscreen;
    notifyListeners();
  }

  /* ───────── END CALL ───────── */

  Future<void> endCall() async {
    if (engine != null) {
      await engine!.endCall();
    }

    callId = null;
    title = null;
    userId = null;
    userName = null;
    engine = null;
    viewMode = CallViewMode.none;

    notifyListeners();
  }
}