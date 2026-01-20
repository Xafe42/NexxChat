import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:nexxchat_firebase/Screens/outgoing_call_screen.dart';
import 'package:nexxchat_firebase/core/services/call_service.dart';

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
    final dateString = widget.payload['date'];
    final timeString = widget.payload['time'];

    final scheduled = DateTime.parse('$dateString $timeString:00');
    final now = DateTime.now();

    if (now.isAfter(scheduled)) {
      isActive = true;
      return;
    }

    final diff = scheduled.difference(now);
    Future.delayed(diff, () {
      if (mounted) {
        setState(() => isActive = true);
      }
    });
  }

  String _formatMonth(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  /// 🔵 JOIN CALL (creates REAL call)
  Future<void> _handleJoinPressed() async {
    if (!isActive) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final callService = CallService();

    // 🔹 Load conversation to know if group or private
    final convSnap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (!convSnap.exists) return;

    final convData = convSnap.data()!;
    final isGroup = convData['isGroup'] == true;
    final members = List<String>.from(convData['members'] ?? []);

    if (members.isEmpty) return;

    String callId;

    if (isGroup) {
      // 🟢 GROUP CALL
      callId = await callService.startGroupCall(
        conversationId: widget.conversationId,
        callerId: currentUser.uid,
        members: members,
        callerName: currentUser.email,
      );
    } else {
      // 🟢 PRIVATE CALL
      final receiverId =
          members.firstWhere((id) => id != currentUser.uid);

      callId = await callService.startPrivateCall(
        conversationId: widget.conversationId,
        callerId: currentUser.uid,
        receiverId: receiverId,
        callerName: currentUser.email,
      );
    }

    if (!mounted) return;

    // 🔵 Go to OutgoingCallScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          callId: callId,
          title: convData['name'] ?? 'Call',
          userId: currentUser.uid,
          userName: currentUser.email ?? 'User',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateString = widget.payload['date'];
    final timeString = widget.payload['time'];
    final note = (widget.payload['note'] ?? '').toString();

    final scheduled = DateTime.parse('$dateString $timeString:00');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatMonth(scheduled.month),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
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
                'Scheduled Call',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20),
              const SizedBox(width: 8),
              Text(
                '$dateString   $timeString',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: const TextStyle(fontSize: 15)),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(
              Icons.call,
              color: isActive ? Colors.white : Colors.grey,
            ),
            label: Text(
              isActive ? 'Join now' : 'Scheduled',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.green : Colors.grey.shade300,
              elevation: isActive ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: isActive ? _handleJoinPressed : null,
          ),
        ],
      ),
    );
  }
}