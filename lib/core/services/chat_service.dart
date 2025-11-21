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
      'typingUsers': [],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUid,
      'typingUsers': [],
    });

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
      String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required String url,
    required String senderUid,
  }) async {
    await _sendGeneric(
      conversationId: conversationId,
      content: url,
      senderUid: senderUid,
      type: 'image',
      lastMessagePreview: '[Photo]',
    );
  }

  Future<void> sendAudioMessage({
    required String conversationId,
    required String url,
    required String senderUid,
    required int duration,
  }) async {
    await _sendGeneric(
      conversationId: conversationId,
      content: url,
      senderUid: senderUid,
      type: 'audio',
      extra: {'duration': duration},
      lastMessagePreview: '[Audio]',
    );
  }

  Future<void> sendVideoMessage({
    required String conversationId,
    required String url,
    required String senderUid,
  }) async {
    await _sendGeneric(
      conversationId: conversationId,
      content: url,
      senderUid: senderUid,
      type: 'video',
      lastMessagePreview: '[Video]',
    );
  }

  Future<void> sendFileMessage({
    required String conversationId,
    required String url,
    required String senderUid,
    required String fileName,
  }) async {
    await _sendGeneric(
      conversationId: conversationId,
      content: url,
      senderUid: senderUid,
      type: 'file',
      extra: {'fileName': fileName},
      lastMessagePreview: '[File]',
    );
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderUid,
    required String senderEmail,
  }) async {
    await _sendGeneric(
      conversationId: conversationId,
      content: text,
      senderUid: senderUid,
      type: 'text',
      extra: {'senderEmail': senderEmail},
      lastMessagePreview: text,
    );
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> updateMessageSeen({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'seenBy': FieldValue.arrayUnion([userId])});
  }

  Future<void> startTyping({
    required String conversationId,
    required String userId,
  }) async {
    await _db.collection('conversations').doc(conversationId).update({
      'typingUsers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> stopTyping({
    required String conversationId,
    required String userId,
  }) async {
    await _db.collection('conversations').doc(conversationId).update({
      'typingUsers': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> _sendGeneric({
    required String conversationId,
    required String content,
    required String senderUid,
    required String type,
    required String lastMessagePreview,
    Map<String, dynamic>? extra,
  }) async {
    final convRef = _db.collection('conversations').doc(conversationId);
    final snap = await convRef.get();
    final members = List<String>.from(snap.data()?['members'] ?? []);

    final receiverId =
        members.firstWhere((m) => m != senderUid, orElse: () => senderUid);

    final msgRef = convRef.collection('messages').doc();

    final data = {
      'id': msgRef.id,
      'content': content,
      'senderId': senderUid,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'seenBy': [],
      ...?extra,
    };

    await msgRef.set(data);

    await convRef.update({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}