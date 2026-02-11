const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

/**
 * CONFIG
 */
const RING_TIMEOUT_MS = 40000; // 40s
const SCHEDULE_RUN = "every 1 minutes";

/**
 * Helper: send incoming call notification (data + notification)
 */
async function notifyIncomingCall({ token, callId, convId, callType }) {
  return getMessaging().send({
    token,
    notification: {
      title: "Incoming call",
      body: callType === "audio" ? "Incoming audio call" : "Incoming video call",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "incoming_calls",
        sound: "default",
        visibility: "public",
      },
    },
    data: {
      type: "incoming_call",
      callId: String(callId),
      conversationId: String(convId),
      callType: String(callType || "video"),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  });
}

/**
 * 1) START DUE CALLS (only once)
 * - Finds scheduled calltime messages due
 * - Transaction: atomically claim message, create call doc, write callId/status
 * - Notify all members
 */
exports.callTimeScheduler = onSchedule(SCHEDULE_RUN, async () => {
  const now = Date.now();

  // pick messages whose time is due and still scheduled
  const dueSnap = await db
    .collectionGroup("messages")
    .where("type", "==", "calltime")
    .where("status", "==", "scheduled")
    .where("scheduledAt", "<=", now)
    .limit(50)
    .get();

  for (const msgDoc of dueSnap.docs) {
    const msgRef = msgDoc.ref;
    const msg = msgDoc.data();
    const convId = msgRef.parent.parent.id;

    // transaction: create call only once
    const created = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(msgRef);
      if (!fresh.exists) return null;

      const freshData = fresh.data();

      // already handled by another scheduler run
      if (freshData.status !== "scheduled") return null;

      // load conversation
      const convRef = db.collection("conversations").doc(convId);
      const convSnap = await tx.get(convRef);
      if (!convSnap.exists) {
        tx.update(msgRef, { status: "cancelled" });
        return null;
      }

      const conv = convSnap.data();
      const members = Array.isArray(conv.members) ? conv.members : [];
      if (members.length < 2) {
        tx.update(msgRef, { status: "cancelled" });
        return null;
      }

      const callType = msg.callType || "video";
      const isGroup = !!conv.isGroup || members.length > 2;

      // create call doc with auto id
      const callRef = db.collection("calls").doc();
      const callId = callRef.id;

      tx.set(callRef, {
        callId,
        conversationId: convId,
        members,
        isGroup,

        callerId: "system",
        callerName: "Scheduled Call",

        callType,
        status: "ringing",
        participants: [],

        scheduledMessageId: msgRef.id,
        createdAt: FieldValue.serverTimestamp(),
        autoEndAtMs: now + RING_TIMEOUT_MS,
      });

      tx.update(msgRef, {
        status: "ringing",
        callId,
        startedAtMs: now,
      });

      return { callId, members, callType };
    });

    if (!created) continue;

    // send notifications (outside transaction)
  // send notifications (outside transaction)
const { callId, members, callType } = created;

for (const uid of members) {
  const userSnap = await db.collection("users").doc(uid).get();
  const token = userSnap.data()?.fcmToken;

  console.log("====== SENDING CALL ======");
  console.log("USER:", uid);
  console.log("TOKEN:", token);

  if (!token) {
    console.log("❌ NO TOKEN FOR USER", uid);
    continue;
  }

  try {
    const res = await notifyIncomingCall({
      token,
      callId,
      convId,
      callType,
    });

    console.log("✅ FCM SENT:", res);
  } catch (e) {
    console.log("🔥 FCM ERROR:", e);
  }
}
  }

  /**
   * 2) AUTO END RINGING CALLS AFTER TIMEOUT
   */
  const ringingSnap = await db
    .collection("calls")
    .where("status", "==", "ringing")
    .where("autoEndAtMs", "<=", now)
    .limit(100)
    .get();

  for (const callDoc of ringingSnap.docs) {
    const callRef = callDoc.ref;
    const call = callDoc.data();

    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(callRef);
      if (!fresh.exists) return;

      const data = fresh.data();
      if (data.status !== "ringing") return;

      tx.update(callRef, {
        status: "missed",
        endedAtMs: now,
      });

      if (data.conversationId && data.scheduledMessageId) {
        const msgRef = db
          .collection("conversations")
          .doc(data.conversationId)
          .collection("messages")
          .doc(data.scheduledMessageId);

        tx.update(msgRef, {
          status: "missed",
        });
      }
    });
  }
});

/**
 * MESSAGE NOTIFICATIONS (normal chat messages)
 * keep your existing one, but ensure path is correct:
 * conversations/{convId}/messages/{messageId}
 */
exports.sendMessageNotification = onDocumentCreated(
  "conversations/{convId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();
    const convId = event.params.convId;

    // skip calltime messages (optional)
    if (msg.type === "calltime") return;

    const senderId = msg.senderId;
    const text = msg.payload?.text || msg.text || "New message";

    const convDoc = await db.collection("conversations").doc(convId).get();
    if (!convDoc.exists) return;

    const conv = convDoc.data();
    const members = conv.members || [];

    for (const uid of members) {
      if (uid === senderId) continue;

      const userDoc = await db.collection("users").doc(uid).get();
      const token = userDoc.data()?.fcmToken;
      if (!token) continue;

      await getMessaging().send({
        token,
        notification: {
          title: conv.title || msg.senderName || "New message",
          body: text,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages",
            sound: "default",
            visibility: "public",
          },
        },
        data: {
          conversationId: convId,
          senderId: senderId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      });
    }
  }
);