import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../call/call_session.dart';
import '../navigation.dart'; // globalNavigatorKey

class CallMiniOverlay extends StatefulWidget {
  const CallMiniOverlay({super.key});

  @override
  State<CallMiniOverlay> createState() => _CallMiniOverlayState();
}

class _CallMiniOverlayState extends State<CallMiniOverlay> {
  Offset _offset = const Offset(20, 120);

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CallSession>();

    // no call
    if (!session.isActive) return const SizedBox.shrink();

    // fullscreen open
    if (session.inFullScreen) return const SizedBox.shrink();

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Draggable(
        feedback: _miniCard(session, dragging: true),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (d) => setState(() => _offset = d.offset),
        child: _miniCard(session),
      ),
    );
  }

  Widget _miniCard(CallSession session, {bool dragging = false}) {
    return Material(
      elevation: dragging ? 14 : 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      child: InkWell(
        onTap: () => _openFullscreen(session),
        child: SizedBox(
          width: 150,
          height: 220,
          child: Stack(
            children: [
              // 🎥 VIDEO or 🎧 AUDIO UI
              Positioned.fill(
                child: session.isVideo
                    ? session.engine!.buildView()
                    : _audioMiniUI(session),
              ),

              // 🔴 END CALL
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => session.end(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎧 Mini UI for audio calls
  Widget _audioMiniUI(CallSession session) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            session.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Audio call',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔼 Restore fullscreen safely
  void _openFullscreen(CallSession session) {
    if (!session.isActive) return;

    // hide mini first
    session.enterFullScreen();

    final nav = globalNavigatorKey.currentState;
    if (nav == null) {
      session.minimize();
      return;
    }

    nav.push(
      MaterialPageRoute(
        builder: (_) => session.buildCallScreen(),
      ),
    );
  }
}