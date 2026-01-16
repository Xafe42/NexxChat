import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final _db = FirebaseFirestore.instance;

  
  Future<String> startPrivateCall({
    required String conversationId,
    required String callerId,
    required String receiverId,
  }) async {
    final callId =
        "${conversationId}_${DateTime.now().millisecondsSinceEpoch}";

    await _db.collection("calls").doc(callId).set({
      "callId": callId,
      "conversationId": conversationId,
      "callerId": callerId,
      "receiverId": receiverId,
      "isGroup": false,
      "isScheduled": false,
      "type": "video",
      "status": "ringing",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return callId;
  }


  Future<String> startGroupCall({
    required String conversationId,
    required String callerId,
    required List<String> members,
  }) async {
    final callId =
        "group_${conversationId}_${DateTime.now().millisecondsSinceEpoch}";

    await _db.collection("calls").doc(callId).set({
      "callId": callId,
      "conversationId": conversationId,
      "callerId": callerId,
      "members": members,
      "isGroup": true,
      "type": "video",
      "status": "ringing",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return callId;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenCall(String callId) {
    return _db.collection("calls").doc(callId).snapshots();
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> listenIncomingPrivateCalls(String userId) {
  return _db
      .collection("calls")
      .where("isGroup", isEqualTo: false)
      .where("receiverId", isEqualTo: userId)
      .where("status", isEqualTo: "ringing")
      .snapshots();
}

  Stream<QuerySnapshot<Map<String, dynamic>>> listenIncomingGroupCalls(String userId) {
  return _db
      .collection("calls")
      .where("isGroup", isEqualTo: true)
      .where("members", arrayContains: userId)
      .where("status", isEqualTo: "ringing")
      .snapshots();
}
  

  Future<void> updateStatus(String callId, String status) async {
    await _db.collection("calls").doc(callId).update({
      "status": status,
    });
  }

 
  Future<void> endCall(String callId) async {
    await updateStatus(callId, "ended");
    
  }
  Future<void> declineCall(String callId) async {
  await _db.collection("calls").doc(callId).update({
    "status": "declined",
    "endedAt": FieldValue.serverTimestamp(),
  });
}
  Future<void> acceptCall(String callId) async {
  await _db.collection("calls").doc(callId).update({
    "status": "accepted",
    "acceptedAt": FieldValue.serverTimestamp(),
  });
}
Future<void> markMissed(String callId) async {
  await _db.collection("calls").doc(callId).update({
    "status": "missed",
    "endedAt": FieldValue.serverTimestamp(),
  });
}
Future<void> finalizeCall({
  required String callId,
  required String status,
  int? duration,
}) async {
  final callRef = _db.collection("calls").doc(callId);
  final snap = await callRef.get();

  if (!snap.exists) return;

  final data = snap.data()!;
  final conversationId = data["conversationId"];

  if (conversationId == null) return;

  final convRef =
      _db.collection("conversations").doc(conversationId);

  final alreadyLogged = data["logged"] == true;
  if (alreadyLogged) return;

  String text;
  switch (status) {
    case "accepted":
      text = "📞 Video call • ${_formatDuration(duration ?? 0)}";
      break;
    case "missed":
      text = "❌ Missed video call";
      break;
    case "declined":
      text = "🚫 Call declined";
      break;
    case "cancelled":
      text = "⏱ Call cancelled";
      break;
    default:
      text = "📞 Video call";
  }

  await convRef.collection("messages").add({
    "type": "call",
    "callId": callId,
    "status": status,
    "duration": duration,
    "text": text,
    "timestamp": FieldValue.serverTimestamp(),
  });

  await convRef.update({
    "lastMessage": text,
    "lastMessageTime": FieldValue.serverTimestamp(),
  });

  await callRef.update({
    "logged": true,
    "status": "ended",
    "endedAt": FieldValue.serverTimestamp(),
  });
}

Future<void> logCallMessage({
  required String conversationId,
  required String callId,
  required String type, // video / audio
  required String status, // accepted / missed / declined / cancelled
  int? duration,
}) async {
  final convRef =
      _db.collection("conversations").doc(conversationId);

  String text;

  switch (status) {
    case "accepted":
      text = "📞 Video call • ${_formatDuration(duration ?? 0)}";
      break;
    case "missed":
      text = "❌ Missed video call";
      break;
    case "declined":
      text = "🚫 Call declined";
      break;
    case "cancelled":
      text = "⏱ Call cancelled";
      break;
    default:
      text = "📞 Video call";
  }

  await convRef.collection("messages").add({
    "type": "call",
    "callId": callId,
    "status": status,
    "duration": duration,
    "text": text,
    "timestamp": FieldValue.serverTimestamp(),
  });

  await convRef.update({
    "lastMessage": text,
    "lastMessageTime": FieldValue.serverTimestamp(),
  });
}

String _formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return "$m:$s";
}

}