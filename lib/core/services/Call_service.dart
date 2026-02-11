import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// START CALL (PRIVATE)
  Future<String> startPrivateCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
    String? callerName,
    String type = "video",
  }) async {
    final callId =
        '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    await _db.collection('calls').doc(callId).set({
      'callId': callId,
      'conversationId': conversationId,

      'callerId': callerId,
      'callerName': callerName,

      'receiverId': receiverId,
      'isGroup': false,
      'members': [callerId, receiverId],

      'participants': [callerId],

      'callType': type,
      'status': 'ringing',

      'createdAt': FieldValue.serverTimestamp(),

      'acceptedAtMs': null,
      'endedAtMs': null,
      'duration': 0,

      'summaryWritten': false,
    });

    return callId;
  }

  /// START CALL (GROUP)
  Future<String> startGroupCall({
    required String conversationId,
    required String callerId,
    required List<String> members,
    String? callerName,
    String type = "video",
  }) async {
    final callId =
        'group_${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    await _db.collection('calls').doc(callId).set({
      'callId': callId,
      'conversationId': conversationId,

      'callerId': callerId,
      'callerName': callerName,

      'members': members,
      'isGroup': true,

      'participants': [callerId],

      'callType': type,
      'status': 'ringing',

      'createdAt': FieldValue.serverTimestamp(),

      'acceptedAtMs': null,
      'endedAtMs': null,
      'duration': 0,

      'summaryWritten': false,
    });

    return callId;
  }

  /// LISTEN CALL
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenCall(
      String callId) {
    return _db.collection('calls').doc(callId).snapshots();
  }

  /// ACCEPT CALL
  Future<void> acceptCall(String callId, String userId) async {
    final ref = _db.collection("calls").doc(callId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final participants =
          List<String>.from(data["participants"] ?? []);

      if (!participants.contains(userId)) {
        participants.add(userId);
      }

      tx.update(ref, {
        "status": "active",
        "participants": participants,
        "acceptedAtMs":
            data["acceptedAtMs"] ??
                DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  /// DECLINE
  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'declined',
      'endedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// CANCEL
  Future<void> cancelCall(String callId) async {
    final ref = _db.collection('calls').doc(callId);
    final snap = await ref.get();

    if (!snap.exists) return;
    if (snap['status'] != 'ringing') return;

    await ref.update({
      'status': 'cancelled',
      'endedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// END CALL
  Future<void> endCall(String callId) async {
    final ref = _db.collection('calls').doc(callId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final status = data['status'];

      if (status == 'ended' ||
          status == 'missed' ||
          status == 'declined' ||
          status == 'cancelled') return;

      final start = data['acceptedAtMs'];
      final now = DateTime.now().millisecondsSinceEpoch;

      int dur = 0;

      if (start != null) {
        dur = ((now - start) / 1000).round();
      }

      tx.update(ref, {
        'status': start == null ? 'missed' : 'ended',
        'endedAtMs': now,
        'duration': dur,
      });
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// CALL SUMMARY
  Future<void> _logCallMessageIfNeeded(String callId) async {
    final callRef = _db.collection('calls').doc(callId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(callRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      if (data['summaryWritten'] == true) return;

      final convId = data['conversationId'];
      final callerId = data['callerId'];
      final status = data['status'];
      final dur = data['duration'] ?? 0;
      final type = data['callType'] ?? 'video';

      if (convId == null || callerId == null) return;

      final convRef =
          _db.collection('conversations').doc(convId);
      final msgRef =
          convRef.collection('messages').doc();

      String text;

      if (status == 'missed') {
        text = type == 'audio'
            ? '📞 Missed audio call'
            : '📹 Missed video call';
      } else if (status == 'declined') {
        text = '🚫 Call declined';
      } else if (status == 'cancelled') {
        text = '⏱ Call cancelled';
      } else {
        text =
            '${type == 'audio' ? '📞' : '📹'} Call ended – ${_format(dur)}';
      }

      tx.set(msgRef, {
        'type': 'call',
        'callId': callId,
        'senderId': callerId,
        'text': text,
        'duration': dur,
        'timestamp': FieldValue.serverTimestamp(),
      });

      tx.update(convRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      tx.update(callRef, {'summaryWritten': true});
    });
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}