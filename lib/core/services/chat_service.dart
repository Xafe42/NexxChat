import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrGetDirectChat({
    required String currentUid,
    required String otherUid,
  }) async {
    final query = await _db
        .collection('conversations')
        .where('isGroup', isEqualTo: false)
        .where('members', arrayContains: currentUid)
        .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final members = List<String>.from(data['members'] ?? []);
      if (members.length == 2 && members.contains(otherUid)) {
        return doc.id;
      }
    }

    final docRef = await _db.collection('conversations').add({
      'isGroup': false,
      'members': [currentUid, otherUid],
      'name': null,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUid,
    });

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
      String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderUid,
    required String senderEmail,
  }) async {
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    await msgRef.add({
      'text': text,
      'type': 'text',
      'senderId': senderUid,
      'senderEmail': senderEmail,
      'time': FieldValue.serverTimestamp(),
    });

    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}