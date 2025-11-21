import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';

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

  // ---------------- MESSAGES STREAM ----------------

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
      String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true) 
        .snapshots();
  }
// ---------------- SEND IMAGE ----------------
Future<void> sendImageMessage({
  required String conversationId,
  required String url,
  required String senderUid,
}) async {
  final convRef = _db.collection('conversations').doc(conversationId);

  // Récupérer les membres pour déterminer le receiverId
  final convSnap = await convRef.get();
  final members = List<String>.from(convSnap.data()?['members'] ?? []);

  final String receiverId = members.firstWhere(
    (m) => m != senderUid,
    orElse: () => senderUid,
  );

  // ID unique du message
  final msgRef = convRef.collection('messages').doc();

  await msgRef.set({
    'id': msgRef.id,
    'content': url,
    'senderId': senderUid,
    'receiverId': receiverId,
    'timestamp': FieldValue.serverTimestamp(),
    'type': 'image',
  });

  // Mise à jour de la conversation
  await convRef.update({
    'lastMessage': '[Photo]',
    'lastMessageTime': FieldValue.serverTimestamp(),
  });
}
  // ---------------- SEND MESSAGE ----------------

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderUid,
    required String senderEmail, 
  }) async {
    
    final convSnap =
        await _db.collection('conversations').doc(conversationId).get();

    final members = List<String>.from(convSnap.data()?['members'] ?? []);
    final String receiverId = members.firstWhere(
      (m) => m != senderUid,
      orElse: () => senderUid,
    );

    final messagesRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    
    final newDoc = messagesRef.doc();

    final message = ChatMessage(
      id: newDoc.id,
      content: text,
      senderId: senderUid,
      receiverId: receiverId,
      timestamp: Timestamp.now(), 
      status: MessageStatus.sent,
    );

    
    await newDoc.set({
      ...message.toMap(),
      'senderEmail': senderEmail,
      'timestamp': FieldValue.serverTimestamp(), 
      'type': 'text',
    });

    
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}