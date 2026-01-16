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

}