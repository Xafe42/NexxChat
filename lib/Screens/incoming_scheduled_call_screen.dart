import 'package:flutter/material.dart';

class IncomingScheduledCallScreen extends StatelessWidget {
  final DateTime scheduledAt;
  final String? note;
  final String title;       
  final VoidCallback onJoin;
  final VoidCallback onDecline;

  const IncomingScheduledCallScreen({
    super.key,
    required this.scheduledAt,
    required this.title,
    required this.onJoin,
    required this.onDecline,
    this.note,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d.$m.$y";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF050816) : const Color(0xFF0A84FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
           
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Scheduled Call",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "${_formatDate(scheduledAt)}  •  ${_formatTime(scheduledAt)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                if ((note ?? "").isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      note!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "decline_call",
                        backgroundColor: Colors.redAccent,
                        onPressed: onDecline,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Decline",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  // Join
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "accept_call",
                        backgroundColor: Colors.greenAccent[400],
                        onPressed: onJoin,
                        child:
                            const Icon(Icons.call_rounded, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Join Call",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: onDecline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}