import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  bool callTriggered = false;

  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  /// ⏰ CHECK TIME
  void _checkActivation() {
    final dateString = widget.payload['date'];
    final timeString = widget.payload['time'];

    final scheduled =
        DateTime.parse('$dateString $timeString:00');

    final now = DateTime.now();

    if (now.isAfter(scheduled)) {
      _triggerScheduledCall();
      return;
    }

    final diff = scheduled.difference(now);

    Future.delayed(diff, () {
      if (!mounted) return;
      _triggerScheduledCall();
    });
  }

  /// 🚀 CREATE CALL FOR ALL MEMBERS
  Future<void> _triggerScheduledCall() async {
    if (callTriggered) return;
    callTriggered = true;

    final convSnap = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (!convSnap.exists) return;

    final data = convSnap.data()!;
    final members =
        List<String>.from(data['members'] ?? []);

    if (members.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('calls')
        .add({
      "conversationId": widget.conversationId,
      "members": members,
      "isGroup": members.length > 2,

      "callerId": "system",
      "callerName": "Scheduled Call",

      "callType": "video",
      "status": "ringing",

      "createdAt":
          FieldValue.serverTimestamp(),

      "autoEndAt":
          DateTime.now()
                  .millisecondsSinceEpoch +
              40000, // 40s timeout
    });

    if (mounted) {
      setState(() => isActive = true);
    }
  }

  String _formatMonth(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dateString = widget.payload['date'];
    final timeString = widget.payload['time'];
    final note =
        (widget.payload['note'] ?? '').toString();

    final scheduled =
        DateTime.parse('$dateString $timeString:00');

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius:
                      BorderRadius.circular(
                          14),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatMonth(
                          scheduled.month),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      scheduled.day
                          .toString(),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Scheduled Call',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                  Icons.access_time,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                '$dateString   $timeString',
                style:
                    const TextStyle(
                        fontSize: 16),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note,
                style:
                    const TextStyle(
                        fontSize: 15)),
          ],
          const SizedBox(height: 16),

          /// STATUS BUTTON (no join)
          ElevatedButton.icon(
            icon: const Icon(
              Icons.call,
              color: Colors.white,
            ),
            label: Text(
              isActive
                  ? 'Calling...'
                  : 'Scheduled',
              style:
                  const TextStyle(
                      fontWeight:
                          FontWeight
                              .w600),
            ),
            style: ElevatedButton
                .styleFrom(
              backgroundColor:
                  isActive
                      ? Colors.green
                      : Colors.grey,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                            14),
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                          horizontal:
                              22,
                          vertical:
                              12),
            ),
            onPressed: null,
          ),
        ],
      ),
    );
  }
}