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
      final members = List<String>.from(doc['members']);
      if (members.length == 2 && members.contains(otherUid)) {
        return doc.id;
      }
    }

    final newDoc = await _db.collection('conversations').add({
      'isGroup': false,
      'members': [currentUid, otherUid],
      'typingUsers': [],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUid,
    });

    return newDoc.id;
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

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderUid,
    required String senderEmail,
  }) async {
    final conv = _db.collection('conversations').doc(conversationId);
    final snap = await conv.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != senderUid, orElse: () => '');

    final doc = conv.collection('messages').doc();

    await doc.set({
      'id': doc.id,
      'content': text,
      'senderId': senderUid,
      'receiverId': receiverUid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': "text",
      'attachment': null,
    });

    await conv.update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required String url,
    required String senderUid,
  }) async {
    final conv = _db.collection('conversations').doc(conversationId);
    final snap = await conv.get();
    final members = List<String>.from(snap['members']);
    final receiverUid =
        members.firstWhere((m) => m != senderUid, orElse: () => '');

    final doc = conv.collection('messages').doc();

    final attachment = {
      "url": url,
      "fileName": "",
      "fileSize": 0,
      "fileExtension": "",
      "type": "IMAGE",
      "uploadStatus": "UPLOADED",
      "autoDownload": false,
      "width": null,
      "height": null,
      "samples": null,
    };

    await doc.set({
      'id': doc.id,
      'content': url,
      'senderId': senderUid,
      'receiverId': receiverUid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "SENT",
      'type': "image",
      'attachment': attachment,
    });

    await conv.update({
      'lastMessage': "[Image]",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}