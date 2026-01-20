import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// START CALL (PRIVATE)
  Future<String> startPrivateCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
    String? callerName,
    String type = "video", // ✅ "video" OR "audio"
  }) async {
    final callId = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    await _db.collection('calls').doc(callId).set({
      'callId': callId,
      'conversationId': conversationId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'isGroup': false,
      'type': type,
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
    String type = "video", // ✅ allow audio too if you want
  }) async {
    final callId = 'group_${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    await _db.collection('calls').doc(callId).set({
      'callId': callId,
      'conversationId': conversationId,
      'callerId': callerId,
      'callerName': callerName,
      'members': members,
      'isGroup': true,
      'type': type,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAtMs': null,
      'endedAtMs': null,
      'duration': 0,
      'summaryWritten': false,
    });

    return callId;
  }

  /// LISTENERS
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenCall(String callId) {
    return _db.collection('calls').doc(callId).snapshots();
  }

  /// Incoming PRIVATE calls (optionally filter by type)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenIncomingPrivateCalls(
    String userId, {
    String? type, // "video" / "audio" / null => all
  }) {
    var q = _db
        .collection('calls')
        .where('isGroup', isEqualTo: false)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing');

    if (type != null) q = q.where('type', isEqualTo: type);

    return q.snapshots();
  }

  /// Incoming GROUP calls (optionally filter by type)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenIncomingGroupCalls(
    String userId, {
    String? type, // "video" / "audio" / null => all
  }) {
    var q = _db
        .collection('calls')
        .where('isGroup', isEqualTo: true)
        .where('members', arrayContains: userId)
        .where('status', isEqualTo: 'ringing');

    if (type != null) q = q.where('type', isEqualTo: type);

    return q.snapshots();
  }

  /// STATE CHANGES
  Future<void> acceptCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'declined',
      'endedAt': FieldValue.serverTimestamp(),
      'endedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// CALLER cancels before accept
  Future<void> cancelCall(String callId) async {
    final ref = _db.collection('calls').doc(callId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    if (data['status'] != 'ringing') return;

    await ref.update({
      'status': 'cancelled',
      'endedAt': FieldValue.serverTimestamp(),
      'endedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// END CALL (caller or callee)
  Future<void> endCall(String callId) async {
    final ref = _db.collection('calls').doc(callId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final status = data['status'];

      // already finished
      if (status == 'ended' ||
          status == 'missed' ||
          status == 'declined' ||
          status == 'cancelled') {
        return;
      }

      final acceptedAtMs = data['acceptedAtMs'] as int?;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      String finalStatus;
      int duration = 0;

      if (acceptedAtMs == null) {
        finalStatus = 'missed';
      } else {
        finalStatus = 'ended';
        duration = ((nowMs - acceptedAtMs) / 1000).round();
      }

      tx.update(ref, {
        'status': finalStatus,
        'endedAt': FieldValue.serverTimestamp(),
        'endedAtMs': nowMs,
        'duration': duration,
      });
    });

    await _logCallMessageIfNeeded(callId);
  }

  /// CALL SUMMARY MESSAGE (writes 1 message only)
  Future<void> _logCallMessageIfNeeded(String callId) async {
    final callRef = _db.collection('calls').doc(callId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(callRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      if (data['summaryWritten'] == true) return;

      final conversationId = data['conversationId'];
      final callerId = data['callerId'];
      final status = (data['status'] ?? '').toString();
      final duration = (data['duration'] ?? 0) as int;
      final type = (data['type'] ?? 'video').toString(); // ✅ audio/video

      if (conversationId == null || callerId == null) return;

      final convRef = _db.collection('conversations').doc(conversationId);
      final msgRef = convRef.collection('messages').doc();

      final isAudio = type == 'audio';

      String text;
      if (isAudio) {
        switch (status) {
          case 'missed':
            text = '📞 Verpasster Sprachanruf';
            break;
          case 'declined':
            text = '🚫 Sprachanruf abgelehnt';
            break;
          case 'cancelled':
            text = '⏱ Sprachanruf abgebrochen';
            break;
          default:
            text = '📞 Sprachanruf beendet – Dauer: ${_format(duration)}';
        }
      } else {
        switch (status) {
          case 'missed':
            text = '📹 Verpasster Videoanruf';
            break;
          case 'declined':
            text = '🚫 Videoanruf abgelehnt';
            break;
          case 'cancelled':
            text = '⏱ Videoanruf abgebrochen';
            break;
          default:
            text = '📹 Videoanruf beendet – Dauer: ${_format(duration)}';
        }
      }

      tx.set(msgRef, {
        'id': msgRef.id,
        'type': 'call',
        'callId': callId,
        'senderId': callerId,
        'status': status,
        'duration': duration,
        'callType': type, // ✅ optional but useful (audio/video)
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      tx.update(convRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      tx.update(callRef, {'summaryWritten': true});
    });
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}