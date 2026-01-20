import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../call/call_session.dart';

class CallMiniOverlay extends StatefulWidget {
  const CallMiniOverlay({super.key});

  @override
  State<CallMiniOverlay> createState() => _CallMiniOverlayState();
}

class _CallMiniOverlayState extends State<CallMiniOverlay> {
  Offset _offset = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CallSession>();

    // ❌ no active call
    if (!session.isActive) return const SizedBox.shrink();

    // ❌ fullscreen open
    if (session.inFullScreen) return const SizedBox.shrink();
    if (ModalRoute.of(context)?.isCurrent == false) {
  return const SizedBox.shrink();
}

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Draggable(
        feedback: _buildMini(context, session, dragging: true),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            _offset = details.offset;
          });
        },
        child: _buildMini(context, session),
      ),
    );
  }

  Widget _buildMini(
    BuildContext context,
    CallSession session, {
    bool dragging = false,
  }) {
    return Material(
      elevation: dragging ? 12 : 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          // 🔼 open fullscreen
          session.enterFullScreen();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => session.buildCallScreen(),
            ),
          );
        },
        child: Stack(
          children: [
            SizedBox(
              width: 150,
              height: 220,
              child: session.engine!.buildView(),
            ),

            // 🔴 End button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () async {
                  await session.end();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
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
    );
  }
}