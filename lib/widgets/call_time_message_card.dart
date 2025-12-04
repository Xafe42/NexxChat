import 'package:flutter/material.dart';

class CallTimeMessageCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const CallTimeMessageCard({super.key, required this.payload});

  String _formatMonth(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dateString = payload["date"];      // "2025-12-09"
    final timeString = payload["time"];      // "18:45"
    final note = payload["note"] ?? "";

    final date = DateTime.parse("$dateString $timeString:00");

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER ----------
            Row(
              children: [
                // DATE BUBBLE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatMonth(date.month),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        date.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                const Text(
                  "Call Time",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
              ],
            ),

            const SizedBox(height: 14),

            // ---------- DATE + TIME ----------
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text("$dateString    $timeString",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),

            const SizedBox(height: 10),

            // ---------- NOTE ----------
            if (note.isNotEmpty)
              Text(
                note,
                style: const TextStyle(fontSize: 15),
              ),

            const SizedBox(height: 20),

            // ---------- JOIN BUTTON ----------
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: HERE YOU TRIGGER THE VIDEO/AUDIO CALL
                },
                icon: const Icon(Icons.call),
                label: const Text("Join Call"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}