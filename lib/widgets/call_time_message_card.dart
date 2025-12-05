import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/Screens/call_screen.dart';

class CallTimeMessageCard extends StatefulWidget {
  final Map<String, dynamic> payload;
  final String conversationId;
  final String messageId;

  const CallTimeMessageCard({
    super.key,
    required this.payload,
    required this.conversationId,
    required this.messageId,
  });

  @override
  State<CallTimeMessageCard> createState() => _CallTimeMessageCardState();
}

class _CallTimeMessageCardState extends State<CallTimeMessageCard> {
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  void _checkActivation() {
    final dateString = widget.payload["date"];
    final timeString = widget.payload["time"];

    final scheduled = DateTime.parse("$dateString $timeString:00");
    final now = DateTime.now();

    if (now.isAfter(scheduled)) {
      setState(() => isActive = true);
      return;
    }

    final diff = scheduled.difference(now);
    Future.delayed(diff, () {
      if (mounted) setState(() => isActive = true);
    });
  }

  String _formatMonth(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[m - 1];
  }

  Future<void> _handleJoinPressed() async {
    if (!isActive) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final dateString = widget.payload["date"];
    final timeString = widget.payload["time"];

    final cleanID = "call_" +
        dateString.replaceAll("-", "") +
        "_" +
        timeString.replaceAll(":", "");

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callID: cleanID,
          userID: currentUser.uid,
          userName: currentUser.email ?? "User",
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      final status = result["status"] ?? "ended";
      final duration = result["duration"];

      final convRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId);
      final msgRef = convRef.collection('messages').doc();

      // call summary message
      await msgRef.set({
        'id': msgRef.id,
        'type': 'call',
        'senderId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'callType': result['type'] ?? 'video',
        'status': status,
        'duration': duration,
      });

      // update conversation last message
      await convRef.update({
        'lastMessage': status == 'missed'
            ? '📞 Verpasster Videoanruf'
            : '📞 Videoanruf beendet',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // 👇 هنا النقطة المهمة: نخفي الـ CallTime القديم
      await convRef
          .collection('messages')
          .doc(widget.messageId)
          .update({'status': 'ended'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = widget.payload["date"];
    final timeString = widget.payload["time"];
    final note = (widget.payload["note"] ?? "").toString();

    final scheduled = DateTime.parse("$dateString $timeString:00");

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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatMonth(scheduled.month),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        scheduled.day.toString(),
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
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  "$dateString    $timeString",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (note.isNotEmpty)
              Text(
                note,
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.call,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
                label: Text(
                  isActive ? "Join Now" : "Scheduled",
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.green : Colors.grey[300],
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: isActive ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                onPressed: isActive ? _handleJoinPressed : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}