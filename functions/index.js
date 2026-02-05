const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendMessageNotification = onDocumentCreated(
  "messages/{messageId}",
  async (event) => {

    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();

    const senderId = msg.senderId;
    const conversationId = msg.conversationId;
    const text = msg.payload?.text || "New message";

    if (!conversationId) return;

    const db = getFirestore();

    const convDoc = await db
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!convDoc.exists) return;

    const conv = convDoc.data();
    const members = conv.members || [];

    for (const uid of members) {
      if (uid === senderId) continue;

      const userDoc = await db.collection("users").doc(uid).get();
      const token = userDoc.data()?.fcmToken;

      if (!token) continue;

      await getMessaging().send({
        token: token,
        notification: {
          title: "New message",
          body: text,
        },
        data: {
          conversationId: conversationId,
        },
      });
    }
  }
);