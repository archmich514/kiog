const admin = require("firebase-admin");

const db = admin.firestore();

// 回答作成時のトリガー処理
async function handleAnswerCreated(snap, context) {
  const answer = snap.data();
  const unitId = answer.unitId;
  const answerUserId = answer.userId;
  const answererName = answer.userName;

  try {
    // UNITのメンバーを取得
    const unitDoc = await db.collection("units").doc(unitId).get();
    if (!unitDoc.exists) {
      console.error(`Unit ${unitId} not found`);
      return;
    }

    const memberIds = unitDoc.data().members || [];

    // 回答者以外のメンバーに通知
    const otherMembers = memberIds.filter(id => id !== answerUserId);

    for (const memberId of otherMembers) {
      try {
        const userDoc = await db.collection("users").doc(memberId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (fcmToken) {
          await admin.messaging().send({
            notification: {
              title: `${answererName}さんがQUEに答えたよ`
            },
            token: fcmToken
          });
          console.log(`Notification sent to ${memberId}`);
        }
      } catch (error) {
        console.error(`Failed to send notification to ${memberId}:`, error);
      }
    }
  } catch (error) {
    console.error(`Error in handleAnswerCreated:`, error);
  }
}

module.exports = { handleAnswerCreated };
