const admin = require("firebase-admin");

async function sendReportNotification(unitId, memberIds) {
  const db = admin.firestore();

  // 各メンバーのFCMトークンを取得して通知送信
  for (const memberId of memberIds) {
    try {
      const userDoc = await db.collection("users").doc(memberId).get();

      if (!userDoc.exists) {
        console.log(`User ${memberId} not found`);
        continue;
      }

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${memberId}`);
        continue;
      }

      const message = {
        notification: {
          title: "今日のKIOGができました",
          body: "二人の今日の会話をまとめました。見てみてね。"
        },
        token: fcmToken
      };

      await admin.messaging().send(message);
      console.log(`Notification sent to user ${memberId}`);
    } catch (error) {
      console.error(`Failed to send notification to ${memberId}:`, error);
    }
  }
}

module.exports = { sendReportNotification };
