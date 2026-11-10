import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/call/call_engine.dart';
import '../core/call/call_session.dart';
import '../core/services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final CallEngine engine;
  final String title;
  final String userId;
  final String userName;
  final String callType;

  const CallScreen({
    super.key,
    required this.callId,
    required this.engine,
    required this.title,
    required this.userId,
    required this.userName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

  bool _ended = false;

  bool _muted = false;
  bool _speakerOn = false;
  bool _videoOn = true;

  bool get _isAudio => widget.callType == 'audio';

  Timer? _timer;
  int _elapsedSec = 0;
  int? _acceptedAtMs;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final session = context.read<CallSession>();

      if (!session.isActive || session.callId != widget.callId) {
        session.start(
          callId: widget.callId,
          engine: widget.engine,
          title: widget.title,
          userId: widget.userId,
          userName: widget.userName,
          type: widget.callType,
        );
      }

      session.enterFullScreen();
    });

    _callSub =
        _callService.listenCall(widget.callId).listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString();

      /// 🔥 SINGLE SOURCE OF TRUTH
      final accepted = data['acceptedAtMs'];
      if (accepted is int && _acceptedAtMs == null) {
        _acceptedAtMs = accepted;
        _startSyncedTimer();
      }

      if (!_ended &&
          (status == 'ended' ||
              status == 'cancelled' ||
              status == 'missed' ||
              status == 'declined')) {
        _ended = true;

        _stopTimer();

        if (!mounted) return;
        await context.read<CallSession>().end();

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  /// ✅ PERFECT SYNC TIMER
  void _startSyncedTimer() {
    _stopTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended || _acceptedAtMs == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;

      setState(() {
        _elapsedSec = ((now - _acceptedAtMs!) / 1000).floor();
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    if (_ended) return;

    _ended = true;
    _stopTimer();

    if (!mounted) return;

    await context.read<CallSession>().end();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _minimizeAndPop() {
    if (_ended || !mounted) return;

    context.read<CallSession>().minimize();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _minimizeAndPop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSub?.cancel();
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop || _ended || !mounted) return;
        context.read<CallSession>().minimize();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _isAudio
                  ? _buildAudioBackdrop()
                  : widget.engine.buildView(),
            ),

            /// ⏱ CALL TIME
            Positioned(
              top: 54,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _fmt(_elapsedSec),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 48,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _minimizeAndPop,
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isAudio ? 'Audio Call' : widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 46,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioBackdrop() {
    return const Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white24,
        child: Icon(Icons.call, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundBtn(
          icon: _muted ? Icons.mic_off : Icons.mic,
          onTap: () {
            setState(() => _muted = !_muted);
            widget.engine.setMuted(_muted);
          },
        ),
        const SizedBox(width: 18),
        _roundBtn(
          icon: _speakerOn ? Icons.volume_up : Icons.hearing,
          onTap: () async {
            setState(() => _speakerOn = !_speakerOn);
            await widget.engine.setSpeaker(_speakerOn);
          },
        ),
        const SizedBox(width: 18),
        _roundBtn(
          icon: Icons.call_end,
          red: true,
          onTap: _endCall,
        ),
      ],
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool red = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: red ? Colors.red : Colors.grey[850],
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}