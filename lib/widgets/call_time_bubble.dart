import 'package:flutter/material.dart';

class CallTimeBubble extends StatelessWidget {
  final Map<String, dynamic> cmd;

  const CallTimeBubble({super.key, required this.cmd});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(cmd["scheduledAt"]);
    final callType = cmd["callType"];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                callType == "video" ? Icons.videocam : Icons.phone,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                "Scheduled Call",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                "${dt.year}-${dt.month}-${dt.day}   ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.call),
            label: Text("Join Call"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              // TODO: Launch Zego VideoCall
            },
          ),
        ],
      ),
    );
  }
}